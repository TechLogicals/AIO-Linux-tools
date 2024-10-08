#! /bin/bash
set -eu

ROOT="$(dirname "${0}")"

function install_gitk {
  gitdir=${HOME}/.config/git
  mkdir -vp "${gitdir}"
  cp -vf \
    "${ROOT}"/git/gitk-{light,light2,light3,dark,dark2,dark3} \
    "${gitdir}"/
}

function install_neovim {
  neovimdir=${HOME}/.config/nvim
  mkdir -vp \
    "${neovimdir}"/colors \
    "${neovimdir}"/autoload/airline/themes
  cp -vf "${ROOT}"/colors/colorific.vim "${neovimdir}"/colors/
  cp -vf \
    "${ROOT}"/autoload/airline/themes/colorific.vim \
    "${neovimdir}"/autoload/airline/themes/
}

function install_alacritty {
  alacrittydir=${HOME}/.config/alacritty
  mkdir -vp "${alacrittydir}"
  cp -vf "${ROOT}"/alacritty/colorific.yml "${alacrittydir}/"
}

function install_kitty {
  kittydir=${HOME}/.config/kitty/themes
  mkdir -vp "${kittydir}"
  cp -vf \
    "${ROOT}"/kitty/{light,light2,light3,dark,dark2,dark3}.conf \
    "${kittydir}/"
}

function install_tmux {
  tmuxdir=${HOME}/.tmux
  mkdir -vp "${tmuxdir}"
  cp -vf \
    "${ROOT}"/tmux/{light,light2,light3,dark,dark2,dark3}.tmuxtheme \
    "${tmuxdir}/"
}

function install_vim {
  vimdir=${HOME}/.vim
  mkdir -vp "${vimdir}"/colors "${vimdir}"/autoload/airline/themes
  cp -vf "${ROOT}"/colors/colorific.vim "${vimdir}"/colors/
  cp -vf \
    "${ROOT}"/autoload/airline/themes/colorific.vim \
    "${vimdir}"/autoload/airline/themes/
}

function print_usage {
  echo "./install usage:"
  echo "  -a|--alacritty   install alacritty files"
  echo "  -g|--gitk        install gitk files"
  echo "  -k|--kitty       install kitty files"
  echo "  -n|--neovim      install neovim files"
  echo "  -t|--tmux        install tmux files"
  echo "  -v|--vim         install vim files"
  echo "  -h|--help        print this message"
}

OPTIONS=aghkntv
LONGOPTIONS=alacritty,git,help,kitty,neovim,tmux,vim
PARSED=$(getopt -o ${OPTIONS} --long ${LONGOPTIONS} -n "${0}" -- "${@}")
eval set -- "${PARSED}"

if [ ${#} -eq 1 ]; then
  install_alacritty
  install_gitk
  install_kitty
  install_neovim
  install_tmux
  install_vim
fi

while [ ${#} -ge 1 ]; do
  case ${1} in
    -a|--alacritty)
      install_alacritty
      shift
      ;;
    -g|--gitk)
      install_gitk
      shift
      ;;
    -k|--kitty)
      install_kitty
      shift
      ;;
    -n|--neovim)
      install_neovim
      shift
      ;;
    -t|--tmux)
      install_tmux
      shift
      ;;
    -v|--vim)
      install_vim
      shift
      ;;
    -h|--help)
      print_usage
      exit
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "ERROR: invalid flag ${2@Q}."
      exit 3
      ;;
  esac
done

echo "Done."