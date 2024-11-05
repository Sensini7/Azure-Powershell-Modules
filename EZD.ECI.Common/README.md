# Module: Common

**Required Permissions**: This module requires no Microsoft Graph permissions to execute.

**Required PowerShell Modules**: This module requires no external modules to execute.

## Public Functions

### Function: Get-ReturnValue

**Description**: Returns a standard exit log message based on the exit code produced by the function calling it. Standard exit codes are as follows.
- 0: **No drift was detected.**
- 1: **An execution error occurred.** This indicates that an unexpected behavior occurred in execution of the parent function, such as being unable to successfully compare current and desired state in its Compare function. This can also indicate an unsuccessful setting update and is returned if drift is still detected in a function's post-execution check.
- 2: **Drift was detected.** This indicates that drift was detected and the function parent function was executed in Drift Detection mode.
- 3: **Change was successful.** This indicates that drift was detected in the parent function's pre-check but was no longer detected in its post-check. This indicates that a setting change took place and was successful. This return code is possible only in deployment mode.