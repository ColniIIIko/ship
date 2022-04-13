#!/usr/bin/env bash
set -e
shopt -s dotglob

project_name="$1"
platform_dir="$2"
cli_dir="$3"

filesToRemove=(
  "bin"
  "docker-compose.yml"
  ".github"
  ".husky"
)

function installService() {
  service="$1"
  service_dir="$2"

  cp -a "ship/services/$service_dir" "$service"

  if [ "$service" != "deploy" ]; then
    cd "$service"
    rm -rf "${filesToRemove[@]}"
    cd ../
  fi
}

# Create the project directory from template

mkdir "$project_name"
cd "$project_name"
cp -a "$cli_dir"/template/. .
echo "# $project_name" > README.md

# Create .gitignore

touch .gitignore
echo ".idea" >> .gitignore
echo "node-modules" >> .gitignore
echo ".DS_Store" >> .gitignore

# Rename services in docker-compose.yml

for i in docker-compose*; do
  perl -i -pe"s/ship/$project_name/g" $i
done

# Install services from ship monorepo

git clone --quiet "https://github.com/paralect/ship"

installService "api" "api"
installService "web" "web"
installService "deploy" "$platform_dir"

rm -rf ship

# Add github actions from deploy service

mv deploy/.github/workflows/* .github/workflows
rm -rf deploy/.github

# Install modules and setup husky

npm install
git init
git add .
git commit -m "initial commit"
git branch -M main
npx husky install
