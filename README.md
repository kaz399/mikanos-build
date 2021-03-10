# mikanos-build (aarch64)

[MikanOS オレオレ AArch64対応版](https://github.com/kaz399/mikanos-aarch64) AArch64対応版のビルド環境を構築します。

Ubuntu20.10で動作確認をしています。

オリジナルのビルド環境構築については[こちら](./README-orig.md)を参照してください。

## ビルド環境の構築

作業ディレクトリを作成ます。  
作業ディレクトリに移りこのリポジトリをクローンします。  
ビルドスクリプトを実行します。  
作業ディレクトリに開発環境一式が構築されます。  

```:bash
mkdir aarch64-mikanos
cd aarch64-mikanos
git clone https://github.com/kaz399/mikanos-build.git osbook
cd osbook/aarch64-buildenv
./bootstrap.sh
```

正しく終了すると下記のような構成になります。

```
aarch64-mikanos
 ├── aarch64-linux-gnu -> gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
 ├── activate.sh
 ├── bootstrap.sh
 ├── clang+llvm-11.0.0-aarch64-linux-gnu
 ├── downloads
 ├── edk2
 ├── freetype2
 ├── gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
 ├── mikanos
 ├── musl
 ├── osbook
 └── seabios
```

## ビルド

作業ディレクトリにある`activate.sh` をsourceしてビルドするアーキテクチャを選択します。

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

```
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
