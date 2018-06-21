Read this in other languages: [English](README.md), [日本語](README.ja.md)

# SiTCP Sample Code for KC705 GMII

KC705通信確認用のSiTCPサンプルソースコード（GMII版）です。

SiTCPの利用するAT93C46のインタフェースをKC705のEEPROM(M24C08)に変換するモジュールを使用しています。

また、KC705に搭載されているI2CスイッチPCA9548Aを動作させるモジュールも使用しています。

ファームウェアをKC705へダウンロードする前に、KC705のリファレンスJ29、J30、J64のジャンパーを
下記のように設定してください（Xilinx UG810参照）。

* J29：ピン1-2間をジャンパー接続
* J30：ピン1-2間をジャンパー接続
* J64：ジャンパーなし


## SiTCP とは

物理学実験での大容量データ転送を目的としてFPGA（Field Programmable Gate Array）上に実装されたシンプルなTCP/IPです。

* SiTCPについては、[SiTCPライブラリページ](https://www.bbtech.co.jp/products/sitcp-library/)を参照してください。
* その他の関連プロジェクトは、[こちら](https://github.com/BeeBeansTechnologies)を参照してください。

![SiTCP](sitcp.png)
