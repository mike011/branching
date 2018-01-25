# from: https://medium.com/ios-os-x-development/ensuring-unique-build-number-while-using-git-flow-and-continuous-integration-8d9de7ae31d4

PARENT_GIT_BRANCH=$(git show-branch \
| grep '*' \
| grep -v "$(git rev-parse --abbrev-ref HEAD)" \
| head -n1 \
| sed 's/.*\[\(.*\)\].*/\1/' \
| sed 's/[\^~].*//')
echo "--------------------------------------------------------"
echo "Getting the latest bundle version from the parent branch: $PARENT_GIT_BRANCH"
echo "--------------------------------------------------------"
# the truth for the current bundle version is on the parent branch, switch branch and get the number
# but first save the branch we are currently on to be able to come back
BUILD_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# make sure you branch exists on the server
git push --set-upstream origin $BUILD_GIT_BRANCH
# make sure you have the newest version on the parent branch
git pull
# switch branch to parent branch
git checkout $PARENT_GIT_BRANCH
# get the current build number from the plist
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "../Branching/Info.plist")
echo "Current bundle version is: $BUNDLE_VERSION"
BUNDLE_VERSION="${BUNDLE_VERSION%.*}.$((${BUNDLE_VERSION##*.}+1))"
# save the new bundle version in info.plist

echo "--------------------------------------------------------"
echo "Bumping version to $BUNDLE_VERSION"
echo "--------------------------------------------------------"
# switch back to the branch we're building
git checkout $BUILD_GIT_BRANCH
# bump and save the bundle version
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "../Branching/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "../BranchingTests/Info.plist"
agvtool new-version $BUNDLE_VERSION
### add the change to the git index
git add ../Branching/Info.plist ../BranchingTests/Info.plist ../Branching.xcodeproj/project.pbxproj
# give a nice commit message
git commit -m "Bumping version to: $BUNDLE_VERSION"
git push

echo "--------------------------------------------------------"
echo "Updating parent branch ($PARENT_GIT_BRANCH) to bumped version"
echo "--------------------------------------------------------"
### cherry pick the last commit from the feature branch to parent branch (commit with the version bump)
# first change to the parent branch
git checkout $PARENT_GIT_BRANCH
#cherry pick the verison bump (--strategy-option theirs forces to accept the change coming in over what is already here)
LAST=$(git log -n 1 $BUILD_GIT_BRANCH --pretty=format:"%H")
git cherry-pick --strategy-option theirs $LAST
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "../Branching/Info.plist")
echo "Version in parent branch is now: $BUNDLE_VERSION"
# push change to parent branch
git push origin $PARENT_GIT_BRANCH
#go back to original branch so we can keep the build process going
git checkout $BUILD_GIT_BRANCH
