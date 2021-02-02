# Bash-Profile
My bash profile for Mac. Not tested on Linux but things like xargs will probably break

### Setup
1. Create a file `.bash_profile_env_vars` in this repository. Use it to store secrets from your environment (API keys, user/pass if you roll that way, etc).
2. Run `source /path/to/this/repo/.bash_profile`
3. If you modify the bash profile, use `ref` to automatically load the newest version

When the profile runs, it will automatically create symlinks from `~/.bash_profile` to  and `~/.bash_profile_env_vars` to `.bash_profile` and `.bash_profile_env_vars` in this repo
