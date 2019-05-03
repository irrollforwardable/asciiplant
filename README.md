# asciiplant
Minimalistic tool for creating ASCII flowcharts written in D language.

### Core package
Located under `source/asciiplant/core`, module name `asciiplant.core`

### GUI tool (currently only a draft)
Location: `source/asciiplant/gui/app.d`

DUB build: `dub build --config=asciiplant-gui --build=plain --arch=x86_64`

### Command line tool
Location: `source/asciiplant/cli/app.d`

DUB build: `dub build --config=asciiplant-cli --build=plain --arch=x86_64`

#### Command line tool usage example
```
>>> nn 1-st node
Node created with id: 1
.---------.
|1-st node|
'---------'

>>> nn 2-nd\nmulitline\nnode
Node created with id: 2
.---------.
|1-st node|
'---------'

.---------.
|2-nd     |
|mulitline|
|node     |
'---------'

>>> nn 3-rd node
Node created with id: 3
.---------.
|1-st node|
'---------'

.---------.
|2-nd     |
|mulitline|
|node     |
'---------'

.---------.
|3-rd node|
'---------'

>>> ll 1 2
Link between nodes (1) and (2) created
.---------.    .---------.
|1-st node|-   |2-nd     |
'---------' '->|mulitline|
               |node     |
.---------.    '---------'
|3-rd node|
'---------'

>>> ll 1 3
Link between nodes (1) and (3) created
.---------.    .---------.
|1-st node|-   |2-nd     |
'---------' '->|mulitline|
     |         |node     |
      \        '---------'
       \
        \      .---------.
         '---->|3-rd node|
               '---------'

>>> set marginx 2
.-------------.    .-------------.
|  1-st node  |-   |  2-nd       |
'-------------' '->|  mulitline  |
       |           |  node       |
        \          '-------------'
         \
          \        .-------------.
           '------>|  3-rd node  |
                   '-------------'

>>> set direction w
.-------------.    .-------------.
|  2-nd       |   -|  1-st node  |
|  mulitline  |<-' '-------------'
|  node       |           |
'-------------'          /
                        /
.-------------.        /
|  3-rd node  |<------'
'-------------'

>>> pp 1 3
The following shortest paths found and marked:
1)      1-st node --[]--> 3-rd node
.-------------.    .=============.
|  2-nd       |   -#  1-st node  #
|  mulitline  |<-' '============='
|  node       |           *
'-------------'          *
                        *
.=============.        *
#  3-rd node  #<*******
'============='
```
