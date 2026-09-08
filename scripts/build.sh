#!/bin/sh
set -e

git -C apps/funflix switch master
git -C apps/funflix-web switch master

cd apps/funflix
funbuild build

cd ../..
cd apps/funflix-web
funbuild build

cd ../..

funbuild push
