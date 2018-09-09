#!/usr/bin/env bash

set -u
set -x

assert()
{
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99

  if [ -z "$2" ]
  then
    exit $E_PARAM_ERR
  fi

  lineno=$2

  if [ ! $1 ]
  then
    echo "Assertion failed:  \"$1\""
    echo "File \"$0\", line $lineno"
    exit $E_ASSERT_FAILED
  fi
}

# **START**

export GOPATH=$HOME
export PATH=$GOPATH/bin:$PATH
echo "machine github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
echo "" >> $HOME/.netrc
echo "machine api.github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
git config --global user.email "$GITHUB_USERNAME@example.com"
git config --global user.name "$GITHUB_USERNAME"
git config --global advice.detachedHead false

# block: setup
mkdir hello
cd hello
go mod init example.com/hello

cat <<EOD > hello.go
package main

import (
	"fmt"
	"rsc.io/quote"
)

func main() {
   fmt.Println(quote.Hello())
}
EOD
gofmt -w hello.go

# block: example
cat hello.go

# block: run
go run .
assert "$? -eq 0" $LINENO

# block: go mod download
go mod download

# block: fake vendor
rm -rf modvendor
tgp=$(mktemp -d)
GOPROXY=file://$GOPATH/pkg/mod/cache/download GOPATH=$tgp go mod download
assert "$? -eq 0" $LINENO
cp -rp $GOPATH/pkg/mod/cache/download/ modvendor
assert "$? -eq 0" $LINENO
GOPATH=$tgp go clean -modcache
assert "$? -eq 0" $LINENO
rm -rf $tgp
assert "$? -eq 0" $LINENO

# block: review modvendor
find modvendor -type f
assert "$? -eq 0" $LINENO

# block: check modvendor
GOPATH=$(mktemp -d) GOPROXY=file://$PWD/modvendor go run .
assert "$? -eq 0" $LINENO

# block: version details
go version
