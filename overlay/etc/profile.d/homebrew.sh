# /etc/profile.d/homebrew.sh
#
# ~/.bash_profile lief bisher nur bei echten Login-Shells -- ein normales
# Terminal-Fenster startet aber eine nicht-login-interaktive Bash, die nur
# ~/.bashrc laedt. Fedoras /etc/bashrc sourced profile.d/*.sh auch in diesem
# Fall (und /etc/profile fuer Login-Shells sowieso), daher hier statt nur in
# .bash_profile: so bekommen beide Shell-Arten den Homebrew-PATH.
[ -x /var/home/linuxbrew/.linuxbrew/bin/brew ] && \
    eval "$(/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
