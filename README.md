Pentego
=======

Ugly conglomeration of Pente and Go into a single project.  Stands here as a learning experience into the realm of git.
The two games are written alongside each other using conditional compilation (D version blocks) instead of something
sensible and extensible.

Compiling
---------
Everything is written in D, so use a D compiler.  In order to compile Pente, simply compile it with version string of
'pente'; Go is 'go'.  I compile with GDC, so I use the command
~~~
gdc -fversion=pente -lncurses -o pente
~~~
Replacing 'pente' with 'go' as the need may be.  The specifics of the commands are different for other compilers; look
up the documentation if you need to.
