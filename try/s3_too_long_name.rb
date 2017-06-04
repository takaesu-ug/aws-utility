# s3オブジェクトのキー名が1024バイトの制限がある事を確認
# http://docs.aws.amazon.com/ja_jp/AmazonS3/latest/dev/UsingMetadata.html
#
# 前提条件
# aws configureでaws s3コマンド実行できる
# sample-takapra というバケットが存在する

require 'tempfile'

bucket_name = 'sample-takapra'
under = 'a' * 1023
just  = 'b' * 1024
over  = 'c' * 1025

Tempfile.create do |f|
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{under}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{just}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{over}`  # エラーになる
end
