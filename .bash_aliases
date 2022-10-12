pac() {
	case $1 in
		"")
			sudo pacman -Syu
			;;
		"up")
			sudo pacman -Syu
			;;
		"in")
			shift
			echo "Calling pacman to install $@"
			echo ""
			sudo pacman -S "$@"
			;;
		"sea")
			shift
			echo "Search for package $@"
			echo ""
			pacman -Ss "$@"
			;;
		"clean")
			du -sh /var/cache/pacman/pkg/
			sudo pacman -Scc
			echo ""
			echo "Orphaned packages..."
			sudo pacman -Rns $(pacman -Qtdq)
			;;
		*)
			echo "Nothing to do . . ."
			;;
	esac
	echo ""
}

alias s='source .bashrc'
alias ..='cd ..'
