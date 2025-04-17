# tasks.nvim

`tasks.nvim` is a task manager for neovim, which is used to integrate with external tools.
It is inspired by VSCode's tasks-manager.

![task_manager](https://img.spacevim.org/94822603-69d0c700-0435-11eb-95a7-b0b4fef91be5.png)

<!-- vim-markdown-toc GFM -->

* [Install](#install)
* [Setup](#setup)
* [Usage](#usage)
    * [Commands](#commands)
    * [Custom tasks](#custom-tasks)
    * [Task Problems Matcher](#task-problems-matcher)
    * [Task auto-detection](#task-auto-detection)
    * [Task provider](#task-provider)
* [Debug](#debug)
* [Self-Promotion](#self-promotion)
* [License](#license)

<!-- vim-markdown-toc -->

There are two kinds of task configurations file by default:

- `~/.tasks.toml`: global tasks configuration
- `.tasks.toml`: project local tasks configuration

The tasks defined in the global tasks configuration can be overrided by project local
tasks configuration.

## Install

With [nvim-plug](https://github.com/wsdjeg/nvim-plug)

```lua
require('plug').add({
  {
    'wsdjeg/tasks.nvim',
    depends = {
      {
        'wsdjeg/code-runner.nvim',
      },
    },
  },
})
```

## Setup

```lua
require('tasks').setup({
  global_tasks = '~/.tasks.toml',
  local_tasks = '.tasks.toml',
  provider = {'npm'},
})
```

## Usage

### Commands

| Key Bindings       | Descriptions                                                            |
| ------------------ | ----------------------------------------------------------------------- |
| `:TasksList`       | list all available tasks                                                |
| `:TasksEdit`       | open local tasks configuration file, use `:TasksEdit!` for global tasks |
| `:TaskSelect`      | select task to run                                                      |
| `:Telescope tasks` | fuzzy find tasks(require `telescope.nvim`)                              |

`:TasksList` will open the tasks manager windows, in the tasks manager windows, you can use `Enter` to run task under the cursor.

If `telescope.nvim` is installed, you can also use `:Telescope tasks` to fuzzy find specific task, and run the select task.

![fuzzy-task](https://img.spacevim.org/199057483-d5cce17c-2f06-436d-bf7d-24a78d0eeb11.png)

### Custom tasks

This is a basic task configuration for running `echo hello world`,
and print the results to the runner window.

```toml
[my-task]
    command = 'echo'
    args = ['hello world']
```

![task hello world](https://img.spacevim.org/74582981-74049900-4ffd-11ea-9b38-7858042225b9.png)

To run the task in the background, you need to set `isBackground` to `true`:

```toml
[my-task]
    command = 'echo'
    args = ['hello world']
    isBackground = true
```

The following task properties are available:

| Name             | Description                                                                             |
| ---------------- | --------------------------------------------------------------------------------------- |
| `command`        | The actual command to execute.                                                          |
| `args`           | The arguments passed to the command, it should be a list of strings and may be omitted. |
| `options`        | Override the defaults for `cwd`,`env` or `shell`.                                       |
| `isBackground`   | Specifies whether the task should run in the background. by default, it is `false`.     |
| `description`    | Short description of the task                                                           |
| `problemMatcher` | Problems matcher of the task                                                            |

**Note**: When a new task is executed, it will kill the previous task. If you want to keep the task,
run it in background by setting `isBackground` to `true`.

`tasks.nvim` supports variable substitution in the task properties, The following predefined variables are supported:

| Name                          | Description                                            |
| ----------------------------- | ------------------------------------------------------ |
| `\${workspaceFolder}`         | The project's root directory                           |
| `\${workspaceFolderBasename}` | The name of current project's root directory           |
| `\${file}`                    | The path of current file                               |
| `\${relativeFile}`            | The current file relative to project root              |
| `\${relativeFileDirname}`     | The current file's dirname relative to workspaceFolder |
| `\${fileBasename}`            | The current file's basename                            |
| `\${fileBasenameNoExtension}` | The current file's basename without file extension     |
| `\${fileDirname}`             | The current file's dirname                             |
| `\${fileExtname}`             | The current file's extension                           |
| `\${cwd}`                     | The task runner's current working directory on startup |
| `\${lineNumber}`              | The current selected line number in the active file    |

For example: Supposing that you have the following requirements:

A file located at `/home/your-username/your-project/folder/file.ext` opened in your editor;
The directory `/home/your-username/your-project` opened as your root workspace.
So you will have the following values for each variable:

| Name                          | Value                                              |
| ----------------------------- | -------------------------------------------------- |
| `\${workspaceFolder}`         | `/home/your-username/your-project/`                |
| `\${workspaceFolderBasename}` | `your-project`                                     |
| `\${file}`                    | `/home/your-username/your-project/folder/file.ext` |
| `\${relativeFile}`            | `folder/file.ext`                                  |
| `\${relativeFileDirname}`     | `folder/`                                          |
| `\${fileBasename}`            | `file.ext`                                         |
| `\${fileBasenameNoExtension}` | `file`                                             |
| `\${fileDirname}`             | `/home/your-username/your-project/folder/`         |
| `\${fileExtname}`             | `.ext`                                             |
| `\${lineNumber}`              | line number of the cursor                          |

### Task Problems Matcher

Problem matcher is used to capture the message in the task output
and show a corresponding problem in quickfix windows.

`problemMatcher` supports `errorformat` and `pattern` properties.

If the `errorformat` property is not defined, the `&errorformat` option will be used.

```toml
[test_problemMatcher]
    command = "echo"
    args = ['.SpaceVim.d/tasks.toml:6:1 test error message']
    isBackground = true
[test_problemMatcher.problemMatcher]
    useStdout = true
    errorformat = '%f:%l:%c\ %m'
```

If `pattern` is defined, the `errorformat` option will be ignored.
Here is an example:

```toml
[test_regexp]
    command = "echo"
    args = ['.SpaceVim.d/tasks.toml:12:1 test error message']
    isBackground = true
[test_regexp.problemMatcher]
    useStdout = true
[test_regexp.problemMatcher.pattern]
      regexp = '\(.*\):\(\d\+\):\(\d\+\)\s\(\S.*\)'
      file = 1
      line = 2
      column = 3
      #severity = 4
      message = 4
```

### Task auto-detection

Currently, this plugin can auto-detect tasks for npm.
the tasks manager will parse the `package.json` file for npm packages.
If you have cloned the [eslint-starter](https://github.com/spicydonuts/eslint-starter). for example, pressing `:TasksList` shows the following list:

![task-auto-detection](https://img.spacevim.org/75089003-471d2c80-558f-11ea-8aea-cbf7417191d9.png)

### Task provider

Some tasks can be automatically detected by the task provider. For example,
a Task Provider could check if there is a specific build file, such as `package.json`,
and create npm tasks.

To build a task provider, you need to use the Bootstrap function.
The task provider should be a vim function that returns a task object.

here is an example for building a task provider.

```lua
local task = require('tasks')

local function make_tasks()
  if vim.fn.filereadable('Makefile') then
    local subcmds = {}
    local conf = {}
    for _, v in ipairs(vim.fn.readfile('Makefile', '')) do
      if vim.startwith(v, '.PHONY') then
        table.insert(subcmds, v)
      end
    end
    for _, subcmd in ipairs(subcmds) do
      local comamnds = vim.fn.split(subcmd)
      table.remove(commands, 1)
      for _, cmd in ipairs(commands) do
        conf = vim.tbl_extend('forces', conf, {
          [cmd] = {
            command = 'make',
            args = {cmd}
            isDetected = true,
            detectedName = 'make:'
          }
        })
      end
    end
    return conf
  else
    return {}
  end
end

task.reg_provider(make_tasks)
```

With the above configuration, you will see the following tasks:

![task-make](https://img.spacevim.org/75105016-084cac80-564b-11ea-9fe6-75d86a0dbb9b.png)

## Debug

Debug with logger.nvim:

```lua
require('plug').add({
  {
    'wsdjeg/tasks.nvim',
    depends = {
      {
        'wsdjeg/code-runner.nvim',
      },
      {
        'wsdjeg/logger.nvim',
      },
    },
  },
})
```

## Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg) and
[Twitter](http://twitter.com/wsdtty).

## License

This project is licensed under the GPL-3.0 License.
