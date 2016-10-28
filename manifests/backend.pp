# == Class: ftep::backend
#
# Install and manage the F-TEP processing back-end components, including
# ZOO-Project's zoo-kernel WPS server and the F-TEP processors.
#
# === Parameters
#
#
#
class ftep::backend() {

  contain ::ftep::backend::zoo_kernel

}
