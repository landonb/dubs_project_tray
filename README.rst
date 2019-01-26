###############################
Dubs Vim |em_dash| Project Tray
###############################

.. |em_dash| unicode:: 0x2014 .. em dash

A simple wrapper around the
`Project <http://www.vim.org/scripts/script.php?script_id=69>`__
plugin.

Additional features:

- Toggle the project tray easily with ``<Alt-Shift-4>``.
  (The key combo was chosen to integrate nicely with
  `Dubs Vim <http://github.com/landonb/dubs-vim>`__.)

- Put your ``.vimprojects`` file anywhere in your Vim
  folder and it'll be located.

- Watch window sizes be fixed after hiding the tray.

- Enjoy a few small usability tweaks to the original
  Project plugin.

Installation
============

Standard Pathogen installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git clone https://github.com/landonb/dubs_project_tray.git

Or, Standard submodule installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git submodule add https://github.com/landonb/dubs_project_tray.git

Online help:

.. code-block:: vim

   :Helptags
   :help dubs-project-tray

Usage
=====

Type ``<Shift-Alt-4>`` once to open the project tray.
Type again to close the project tray. Repeat.

This project includes a starter ``.vimprojects``
file. When you open the project tray, you'll see
some comments at the top of the file. Read them.

* tl;dr, in command mode, type ``\c`` and answer two
  questions -- give your new project a name, and then
  enter its absolute path -- and project will create
  a new project for you.

Hints: If you have two or more projects and would like
to reorder them, rather than selecting, copying and
pasting, there's an easier way. First, collapse all
directories by typing ``zM``, and then move the cursor
on to the same line as the collapsed project you want
to move. Finally, type ``<Ctrl-Up>`` and ``<Ctrl-Down>``
to swap the whole project with the line above or the
line below; press the key combo multiple times to move
the project to a new position.

Key Mappings
============

===========================  ============================  ==============================================================================
 Key Mapping                  Description                   Notes
===========================  ============================  ==============================================================================
 ``Shift-Alt-4``              Toggle Project tray           As mentioned above, ``Shift-Alt-4`` toggles the project tray.
                                                            You can browse or search the project tray and double-click
                                                            or press <enter> in command mode (not insert mode) to open files.
                                                            Be sure you've edited ``~/.vim/.vimprojects`` and setup the
                                                            project hierarchies (read the instructions at the top of the
                                                            file; basically, use ``\c`` to add a new project).
===========================  ============================  ==============================================================================

Brackets in Directory Names
===========================

Bug: There's an issue handling directories with
brackets in their names, such as those used in a
`cookiecutter <https://github.com/audreyr/cookiecutter>`__
which uses the `Jinja template engine <http://jinja.pocoo.org/>`__
which uses brackets, e.g., ``cc-pyproject/{{project_name}}``.

Specifically, folding doesn't work well. If the fold
name is shorter than the project window width, e.g.,

.. code-block:: vim

   ex={{example}} {

then the built-in ``za`` command works (which toggles
folding), albeit not until after typing it at least
three times. But if the name is wider than the project
window, e.g.,

.. code-block:: vim

   long_{{example}}={{exammmmmmmmmmmmmmmmmmmmmple}} {

so the text is clipped by the Vim window, using ``za``
changes the name of the fold, e.g., from

.. code-block:: vim

   long_{{example}}={{exammmmmmmmmmmmmmmmmmmmmple}} {

to

.. code-block:: vim

       long_{example}}------

(with leading spaces, too)
but doesn't collapse the directory listing.

I wouldn't normally note a bug in a readme but this
problem seems inherent to Vim and is something I'll
probably never fix.

