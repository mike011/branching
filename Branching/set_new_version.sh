# from: https://medium.com/ios-os-x-development/ensuring-unique-build-number-while-using-git-flow-and-continuous-integration-8d9de7ae31d4

echo "--------------------------------------------------------"
echo "Getting the latest bundle version from develop"
echo "--------------------------------------------------------"
# the truth for the current bundle version is on develop, switch branch and get the number
# but first save the branch we are currently on to be able to come back
BUILD_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# make sure you branch exists on the server
git push --set-upstream origin $BUILD_GIT_BRANCH
# make sure you have the newest version of develop
git pull
# switch branch
git checkout develop
# get the current build number from the plist
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "Branching/Info.plist")
echo "Current bundle version is: $BUNDLE_VERSION"

echo "--------------------------------------------------------"
echo "Bumping version"
echo "--------------------------------------------------------"
# switch back to the branch we're building
git checkout $BUILD_GIT_BRANCH
# bump and save the bundle version
BUNDLE_VERSION=$(($BUNDLE_VERSION + 1))
# save the new bundle version in info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "Branching/Info.plist"
### add the change to the git index
git add Branching/Info.plist
# give a nice commit message
NEW_VERSION="Bumping version to: $BUNDLE_VERSION"
echo $NEW_VERSION
git commit -m "$NEW_VERSION"
git push

echo "--------------------------------------------------------"
echo "Updating develop to have the bumped version"
echo "--------------------------------------------------------"
### cherry pick the last commit from the feature branch to develop (commit with the version bump)
# first change to the develop branch
git checkout develop
#cherry pick the verison bump (--strategy-option theirs forces to accept the change coming in over what is already here)
LAST=$(git log -n 1 $BUILD_GIT_BRANCH --pretty=format:"%H")
git cherry-pick --strategy-option theirs $LAST
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "Branching/Info.plist")
echo "Version in develop is now: $BUNDLE_VERSION"
# push change to develop
git push origin develop
#go back to original branch so we can keep the build process going
git checkout $BUILD_GIT_BRANCH
