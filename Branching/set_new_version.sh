# from: https://medium.com/ios-os-x-development/ensuring-unique-build-number-while-using-git-flow-and-continuous-integration-8d9de7ae31d4

echo "--------------------------------------------------------"
echo "Making sure you have the latest greatest version"
echo "--------------------------------------------------------"
git pull

echo "--------------------------------------------------------"
echo "Getting the latest bundle version from develop"
echo "--------------------------------------------------------"
# the truth for the current bundle version is on develop, switch branch and get the number
# but first save the branch we are currently on to be able to come back
BUILD_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# switch branch
git checkout develop
# get the current build number from the plist
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "Branching/Info.plist")
echo "Current bundle version is: $BUNDLE_VERSION"

echo "--------------------------------------------------------"
echo "Bumping version on $BUILD_GIT_BRANCH"
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
NEW_VERSION = "Bumping version to: $BUNDLE_VERSION"
echo $NEW_VERSION
git commit -m $NEW_VERSION

echo "--------------------------------------------------------"
echo "Pushing the changes to GitHub"
echo "--------------------------------------------------------"
# get the current branch
git rev-parse --abbrev-ref HEAD
# push all changes
git push --set-upstream origin $GIT_BRANCH

echo "--------------------------------------------------------"
echo "Updating develop to having the newer version"
echo "--------------------------------------------------------"
### cherry pick the last commit from the feature branch to develop (commit with the version bump)
# first change to the develop branch
git checkout develop
#cherry pick (--strategy-option theirs forces to accept the change coming in over what is already here)
LAST=$(git rev-parse HEAD)
git cherry-pick $GIT_BRANCH --strategy-option theirs $LAST
# push change to develop
git push origin develop
#go back to original branch so we can keep the build process going
git checkout $GIT_BRANCH
