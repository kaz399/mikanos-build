# mikanos-build (aarch64)

[MikanOS オレオレ AArch64対応版](https://github.com/kaz399/mikanos-aarch64) AArch64対応版のビルド環境を構築します。

Ubuntu20.10で動作確認をしています。

オリジナルのビルド環境構築については[こちら](./README-orig.md)を参照してください。

## ビルド環境の構築

作業ディレクトリを作成ます。  
作業ディレクトリに移りこのリポジトリを`osbook`という名前でクローンします。  

```:bash
mkdir aarch64-mikanos
cd aarch64-mikanos
git clone https://github.com/kaz399/mikanos-build.git osbook
```

例として作業ディレクトリを`aarch64-mikanos`とします。  
ディレクトリ構成は下記になります。  

```
aarch64-mikanos
 └── osbook/
```

`osbook/aarch64-buildenv/`に移動し、環境構築スクリプト`bootstrap.sh`を実行します。  
作業ディレクトリに開発環境一式が構築されます。  

```:bash
cd osbook/aarch64-buildenv
./bootstrap.sh
```

環境構築が終了すると下記の構成になります。

```
aarch64-mikanos
├── aarch64-linux-gnu -> gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
├── activate.sh
├── clang+llvm-11.0.0-aarch64-linux-gnu/
├── downloads/
├── edk2/
├── freetype2/
├── gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/
├── mikanos/
├── musl/
├── osbook/
└── seabios/

10 directories, 1 file
```

## ビルド

作業ディレクトリにある`activate.sh` をsourceします。  
`activate.sh`の引数でビルドするアーキテクチャを選択します。  

別アーキテクチャに切り替えるときは`deactivate`を実行してから再度`activate.sh`をsourceしなおしてください。

### aarch64バイナリをビルドする場合

```:bash
. ./activate.sh
```

### x86_64バイナリをビルドする場合

```:bash
. ./activate.sh x86_64
```

### loaderとkernelのビルド

`mikanos/kernel`ディレクトリに移り、loaderとkernelをビルドします。

```:bash
cd mikanos/kernel
make loader
make
```

### QEMUでの実行

下記コマンド（エイリアス）を実行するとkernelをEMUで実行します。  
`disk.img`を作成するために`sudo`を実行するので、パスワードを聞いてきます。  


### aarch64バイナリを実行する場合

```:bash
ra
```

### x86_64バイナリを実行する場合

```:bash
rk
```
