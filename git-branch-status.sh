#!/bin/bash
# by https://github.com/minhluantran017
# modified from http://github.com/kortina
# modified from http://github.com/jehiah
# this prints out branch ahead/behind status vs origin/master for all branches
RED=$'\e[1;31m'
BLU=$'\e[1;32m'
YEL=$'\e[1;33m'
WHI=$'\e[0m'

echo "${YEL}Inside each branch..."
git for-each-ref --format="%(refname:short) %(upstream:short)" refs/ | \
while read local remote
do
	if [ $local != "origin/"* ]; then
		remote="origin/$local"
		git rev-list --left-right ${local}...${remote} -- 2>/dev/null >/tmp/git_upstream_status_delta || continue
		LEFT_AHEAD=$(grep -c '^<' /tmp/git_upstream_status_delta)
		RIGHT_AHEAD=$(grep -c '^>' /tmp/git_upstream_status_delta)
		echo "${BLU}$local $WHI(ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) ${RED}$remote ${WHI}"
	fi
done  | grep -v "^origin/master" | sort | uniq

echo 
echo "${YEL}Local branches vs master..."
git for-each-ref --format="%(refname:short) %(upstream:short)" refs/ | \
while read local remote
do
	if [[ $local != "origin/"* ]]; then
		branches=("$local")
	fi;
	for branch in ${branches[@]}; do
		master="master"
		git rev-list --left-right ${branch}...${master} -- 2>/dev/null >/tmp/git_upstream_status_delta || continue
		LEFT_AHEAD=$(grep -c '^<' /tmp/git_upstream_status_delta)
		RIGHT_AHEAD=$(grep -c '^>' /tmp/git_upstream_status_delta)
		echo "${BLU}$branch $WHI(ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) ${RED}$master ${WHI}"
	done
done  | grep -v "^master" | sort | uniq

echo
echo "${YEL}Remote branches vs master..."
git for-each-ref --format="%(refname:short) %(upstream:short)" refs/ | \
while read local remote
do
	if [[ $local != "origin/"* ]]; then
		branches=("origin/$local")
	fi;
	for branch in ${branches[@]}; do
		master="origin/master"
		git rev-list --left-right ${branch}...${master} -- 2>/dev/null >/tmp/git_upstream_status_delta || continue
		LEFT_AHEAD=$(grep -c '^<' /tmp/git_upstream_status_delta)
		RIGHT_AHEAD=$(grep -c '^>' /tmp/git_upstream_status_delta)
		echo "${BLU}$branch $WHI(ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) ${RED}$master ${WHI}"
	done
done  | grep -v "^origin/master" | sort | uniq
echo
