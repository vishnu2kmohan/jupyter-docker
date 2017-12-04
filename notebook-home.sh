#!/bin/bash

source "$HOME/.bash_profile"
source activate jupyter
jupyter lab "$@"
