FROM ubuntu:jammy

RUN apt-get update
RUN apt-get -y install wget curl git

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

WORKDIR /nvim
RUN wget https://github.com/neovim/neovim/releases/download/v0.9.0/nvim.appimage
RUN chmod +x ./nvim.appimage
RUN ./nvim.appimage --appimage-extract

WORKDIR /src

RUN git clone https://github.com/sourcegraph/create.git

CMD mkdir /root/.config/nvim
COPY . sourcegraph.nvim
COPY test/configs/minimal.vimrc /root/.vimrc
COPY test/configs/init.vim /root/.config/nvim/init.vim

RUN /nvim/squashfs-root/AppRun --headless -c "PlugInstall --sync" -c "qa"

WORKDIR /src/create

CMD ["/nvim/squashfs-root/AppRun", "--headless", "-c", "PlenaryBustedFile /src/sourcegraph.nvim/test/plenary/test.lua", "-c", "qa"]
