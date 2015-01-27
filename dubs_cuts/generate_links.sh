#!/bin/bash

# Run this command to quickly make links to all your
# bundled Vim files -- Pathogen is a beautiful
# distribution and management tool, but one side
# effect is that instead of one plugin/ directory,
# now you've got two dozen.

# Remove existing links, otherwise you'll
# add links to the linked directories.

find . -maxdepth 1 -type l -exec /bin/rm {} +

# Name the links deliberately so they're
# ordered logically and are pretty printed
# in the project tray.

padline1='---------'
for fpath in $(find ~/.vim/bundle/dubs* \
                    ~/.vim/autoload \
                      -type f \
                      -regextype "posix-egrep" \
                      -regex ".*\.(in|py|rb|rst|sh|txt|vim)(rc)?$" \
               | egrep -v "\/autoload\/xml" \
              ) ; do
  if [[ $fpath != ' ' ]]; then
    filename=$(basename $fpath)
    filedir=$(basename $(dirname $fpath))
    proj_name=$(basename $(dirname $(dirname $fpath)))
    if [[    $proj_name == '' \
          || $proj_name == 'bundle' \
          || $proj_name == 'packages' ]]; then
      filedir_=${filedir}
    else
      filedir_=${filedir:0:9}
    fi
    link_name=$(printf "%s%s-%s" \
                       "$filedir_" \
                       "${padline1:${#filedir_}}" \
                       "$filename")
    # Using -f, because file shortening may make two files look like one:
    # e.g., dubs_all/cmdt_paths/generate_links.sh
    #       dubs_file_finder/cmdt_paths.template/generate_links.sh
    #    both resolve to cmdt_path-generate_links.sh.
    # Obviously, remove -f to see what files conflict.
    /bin/ln -sf $fpath $link_name
  fi
done

# The two symlinks were neglected by the find and
# their dubs_cuts names end up buried in the readmes.
/bin/ln -s ~/.vim/bundle/dubs_all/dubs_projects.vim dubs_all--dubs_projects.vim
/bin/ln -s ~/.vim/bundle/dubs_all/dubs_tagpaths.vim dubs_all--dubs_tagpaths.vim

/bin/ln -s ~/.vim/README.rst dubs_all--README.rst
/bin/ln -s ~/.vim/README-FIXME.rst dubs_all--README-FIXME.rst
/bin/ln -s ~/.vim/README-USING.rst dubs_all--README-USING.rst

