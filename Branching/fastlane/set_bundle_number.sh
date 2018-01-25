# from: https://medium.com/ios-os-x-development/ensuring-unique-build-number-while-using-git-flow-and-continuous-integration-8d9de7ae31d4
if [ -z "$1" ]
then
  echo "You have to pass in the name of branch you branched from as the first argument. More then likely it is release."
  exit
fi

ORIGINATING_GIT_BRANCH=$1

echo "--------------------------------------------------------"
echo "Getting the latest bundle version from the originating branch: $ORIGINATING_GIT_BRANCH"
echo "--------------------------------------------------------"
# the truth for the current bundle version is on the originating branch, switch branch and get the number
# but first save the branch we are currently on to be able to come back
BUILD_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# make sure you branch exists on the server
git push --set-upstream origin $ORIGINATING_GIT_BRANCH
# make sure you have the newest version on the originating branch
git pull
# switch branch to originating branch
git checkout $ORIGINATING_GIT_BRANCH
# get the current build number from the plist
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "../Branching/Info.plist")
echo "Current bundle version is: $BUNDLE_VERSION"

echo "--------------------------------------------------------"
echo "Setting version in $BUILD_GIT_BRANCH to $BUNDLE_VERSION"
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
git commit -m "Setting version to $BUNDLE_VERSION"
git push

git checkout $BUILD_GIT_BRANCH
