# from: https://medium.com/ios-os-x-development/ensuring-unique-build-number-while-using-git-flow-and-continuous-integration-8d9de7ae31d4

# make sure you have the latest greatest version
git pull

# the truth for the current bundle version is on develop, switch branch and get the number
# but first save the branch we are currently on to be able to come back
BUILD_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# switch branch
git checkout develop
# get the current build number from the plist
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "Branching/Info.plist")
# bump and save the bundle version
BUNDLE_VERSION=$(($BUNDLE_VERSION + 1))

# switch back to the branch we're building
git checkout $BUILD_GIT_BRANCH
# save the new bundle version in info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "Branching/Info.plist"
echo "Build number set to: $BUNDLE_VERSION"

### add the change to the git index
git add Branching/Info.plist
# give a nice commit message
git commit -m "Bumping version to: $BUNDLE_VERSION"

### push changes to server for the release branch
# get the current branch
git rev-parse --abbrev-ref HEAD
# push all changes
git push --set-upstream origin $GIT_BRANCH
### cherry pick the last commit from the release branch to develop (commit with the version bump)
# first change to the develop branch
git checkout develop
#cherry pick (--strategy-option theirs forces to accept the change coming in over what is already here)
LAST=$(git rev-parse HEAD)
echo git cherry-pick $GIT_BRANCH --strategy-option theirs $LAST
git cherry-pick $GIT_BRANCH --strategy-option theirs $LAST
# push change to develop
git push origin develop
#go back to original branch so we can keep the build process going
git checkout $GIT_BRANCH
