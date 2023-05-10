# chmenu
Simple TUI program which takes an associative list of `title` - `shell command` and executes a corresponding command based on what the user has chosen.

# Controls
| Key                            | Action                                         |
|--------------------------------|------------------------------------------------|
| <kbd>DOWN</kbd> / <kbd>n</kbd> | Move selection to the next option.             |
| <kbd>UP</kbd>   / <kbd>p</kbd> | Move selection to the previous option.         |
| <kbd>ENTER</kbd>               | Exit with executing the corresponding command. |
| <kbd>q</kbd>                   | Exit without executing anything.               |

# Options
| Option | Desctiption                                                                                                            |
|--------|------------------------------------------------------------------------------------------------------------------------|
| `-h`   | Print the help message.                                                                                                |
| `-a N` | Automatically select the first option if there was no user activity in the first N miliseconds of running the program. |

# Preview
 ![chmenu preview](./preview.gif)
