pakku() {
	case $1 in
		"") pakku up;;
		"up")
			echo "Update"
			;;
		"in")
			shift
			if [[ $(pacman -Ss "$@") ]]; then
				while true; do
				    read -p "Do you want to install this package? (y/n) " yn
				    case $yn in
					[Yy]* ) sudo pacman -Ss "$@" --noconfirm; break;;
					[Nn]* ) break;;
					* ) echo "Please answer yes or no.";;
				    esac
				done
			else
			    echo "Package $@ not found"
			fi
			;;
		"rm")
			shift
			sudo pacman -Rsn "$@"
			;;
		"sea")
			shift
			pacman -Ss "$@"
			;;
		"clean")
			while true; do
			    du -sh /var/cache/pacman/pkg/
			    read -p "Clean package cache? (y/n) " yn
			    case $yn in
				[Yy]* ) sudo pacman -Scc --noconfirm; break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			    esac
			done
			while true; do
			    read -p "Clean orphaned packages? (y/n) " yn
			    case $yn in
				[Yy]* ) sudo pacman -Rns $(pacman -Qtdq) --noconfirm; break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
			    esac
			done
			;;
		*)
			echo "Nothing to do..."
			;;
	esac
}

alias s='source .bashrc'
alias ..='cd ..'
