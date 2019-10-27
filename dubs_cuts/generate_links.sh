#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh
# 2019-10-27: (lb): I'd rather all infusers be pure sh/POSIX,
#   but there's some array usage below (e.g., fpath_dirs+=())
#   which is not POSIX-compliant, and also ${subscripting:0:6}.

# Run this command to quickly make links to all your
# bundled Vim files -- Pathogen is a beautiful
# distribution and management tool, but one side
# effect is that instead of one plugin/ directory,
# now you've got two dozen.

DUBS_PROJECT_TRAY_DUBS_CUTS="${HOME}/.vim/bundle_/dubs_project_tray/dubs_cuts"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dubs_cuts_generate_links () {
  # Caller ensures we're in the proper directory, but just in case:
  if [ $(basename -- "$(pwd -P)") != 'dubs_cuts' ]; then
    >&2 echo 'Where am I?!'
    exit 1
  fi

  # Remove existing links, otherwise you'll
  # add links to the linked directories.
  find . -maxdepth 1 -type l -exec /bin/rm {} +

  # Ignore searching subdirectories symlinked herein.
  if [ ! -e '.ignore' ]; then
    echo '*' > '.ignore'
  elif ! (cat '.ignore' | grep '^\*$' > /dev/null); then
    >&2 echo 'WARNING: dubs_cuts/.ignore missing ‘*’ entry!'
  fi

  # Name the links deliberately so they're
  # ordered logically and are pretty printed
  # in the project tray.

  local fpath_dirs=()

  add_dubs_all=true
  if [ -e ~/.vim/bundle_ ]; then
    fpath_dirs+=(~/.vim/bundle_/dubs*)
    # 2018-03-13: Don't forget my privates!
    fpath_dirs+=(~/.vim/bundle_/${USER}*)
  elif [ -e ~/.vim/bundle ]; then
    fpath_dirs+=(~/.vim/bundle/dubs*)
    add_dubs_all=false
  fi
  if ${add_dubs_all}; then
    if [ -e ~/.vim/bundle/dubs_all ]; then
      fpath_dirs+=(~/.vim/bundle/dubs_all)
    fi
  fi

  fpath_dirs+=(~/.vim/autoload)

  local padline1='---------'
  for fpath in $( \
    find ${fpath_dirs[@]} \
      -type f \
      -regextype "posix-egrep" \
      -regex ".*\.(in|py|rb|rst|sh|txt|vim)(rc)?$" \
    | egrep -v "\/autoload\/xml" \
  ) ; do
    if true; then
      echo "==================================================================="
      echo "FOUND: ${fpath}"
    fi
    if [ "${fpath}" != ' ' ]; then
      filename=$(basename -- "${fpath}")
      rpath=$(dirname -- "${fpath}")
      proj_name=$(basename -- $(dirname $(dirname -- "${fpath}")))
      path_abbrevd=''
      if    [ "${proj_name}" = '' ] \
         || [ "${proj_name}" = 'bundle' ] \
         || [ "${proj_name}" = 'bundle_' ] \
         || [ "${proj_name}" = 'packages' ] \
      ; then
        path_abbrevd="${proj_name:0:4}"
      else
        parent_name=$(basename -- "${rpath}")
        while [[ \
          "${parent_name}" != '/' &&
          "${parent_name}" != '.vim' &&
          "${parent_name:0:6}" != 'bundle' \
        ]]; do
          proj_name=$(basename -- "${rpath}")
          proj_name=${proj_name#dubs_}
          proj_name=${proj_name#${USER}s_}
          proj_name=${proj_name:0:8}
          rpath=$(dirname -- "${rpath}")
          parent_name=$(basename -- "${rpath}")
          [ "${path_abbrevd}" != '' ] && path_abbrevd="-${path_abbrevd}"
          path_abbrevd="${proj_name:0:8}${path_abbrevd}"
        done
        if [ "${parent_name}" = '.vim' ]; then
          # If top-level ~/.vim/plugin or ~/.vim/autoload, etc.
          [ "${path_abbrevd}" != '' ] && path_abbrevd="-${path_abbrevd}"
          path_abbrevd="${parent_name:0:8}${path_abbrevd}"
        fi
      fi
      link_name=$( \
        printf "%s%s-%s" \
          "${path_abbrevd}" \
          "${padline1:${#path_abbrevd}}" \
          "${filename}" \
      )
      if true; then
          echo "  filename: ${filename}"
          echo "  rpath: ${rpath}"
          echo "  proj_name: ${proj_name}"
          echo "  path_abbrevd: ${path_abbrevd}"
          echo "  link_name: ${link_name}"
      fi
      # Using -f, because file shortening may make two files look like one:
      # e.g., dubs_all/cmdt_paths/generate_links.sh
      #       dubs_file_finder/cmdt_paths.template/generate_links.sh
      #    both resolve to cmdt_path-generate_links.sh.
      # Obviously, remove -f to see what files conflict.
      /bin/ln -sf "${fpath}" "${link_name}"
    fi
  done

  # The two symlinks were neglected by the find and
  # their dubs_cuts names end up buried in the readmes.
  /bin/ln -s ~/.vim/bundle_/dubs_grep_steady/dubs_projects.vim dubs_all--dubs_projects.vim
  /bin/ln -s ~/.vim/bundle_/dubs_edit_juice/dubs_tagpaths.vim dubs_all--dubs_tagpaths.vim

  /bin/ln -s ~/.vim/README.rst dubs_all--README.rst
  /bin/ln -s ~/.vim/README-FIXME.rst dubs_all--README-FIXME.rst
  /bin/ln -s ~/.vim/README-USING.rst dubs_all--README-USING.rst
  /bin/ln -s ~/.vim/readme-using.pt1.rst dubs_all--readme-using.pt1.rst
  /bin/ln -s ~/.vim/readme-using.pt2.rst dubs_all--readme-using.pt2.rst
  /bin/ln -s ~/.vim/readme-using.make.sh dubs_all--readme-using.make.sh

  # 2017-02-25: Huh? I wonder if the `ln -sf` in the loop overwrites it...
  /bin/ln -sf \
    ~/.vim/bundle_/dubs_file_finder/cmdt_paths/generate_links.sh \
    cmdt_path-generate_links.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  local before_cd="$(pwd -L)"
  cd "${DUBS_PROJECT_TRAY_DUBS_CUTS}"

  set -e

  dubs_cuts_generate_links

  cd "${before_cd}"
}

main "$@"

