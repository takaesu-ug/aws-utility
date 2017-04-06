aws-utility
===========

## Usage

AWS Utility Tools

```
# create snapshots.
30 1,13 * * * source $HOME/.bashrc && cd /data/scripts/aws_utilities/ && bundle exec ruby create_snapshot.rb 2>&1 | logger -t create_snapshot -p local0.info
0 4 * * 6     source $HOME/.bashrc && cd /data/scripts/aws_utilities/ && bundle exec ruby create_ami.rb 2>&1      | logger -t create_ami -p local0.info
```

## References
* [AWSで構築した環境にありがちなシェルスクリプトたち まとめ ｜ Developers.IO](http://dev.classmethod.jp/cloud/aws/aws-shellscript-summary/)
