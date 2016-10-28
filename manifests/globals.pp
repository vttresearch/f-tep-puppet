# Class for setting cross-class global overrides.
class ftep::globals(
  $manage_package_repo = true,
) {
  # Setup of the repo only makes sense globally, so we are doing this here.
  if($manage_package_repo) {
    class { 'ftep::repo': }
  }
}