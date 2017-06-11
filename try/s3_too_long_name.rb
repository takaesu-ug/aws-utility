# s3オブジェクトのキー名が1024バイトの制限がある事を確認
# http://docs.aws.amazon.com/ja_jp/AmazonS3/latest/dev/UsingMetadata.html
#
# 前提条件
# aws configureでaws s3コマンド実行できる
# sample-takapra というバケットが存在する

require 'tempfile'

# bucket_name = 'sample-takapra'
bucket_name = 't2-takapra'
under = 'a' * 1023
just  = 'b' * 1024
over  = 'c' * 1025

# 単純なファイル名のみ
Tempfile.create do |f|
  puts under.bytesize
  puts just.bytesize
  puts over.bytesize

  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{under}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{just}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{over}`  # エラーになる
end


# スラッシュも含むファイル
# S3マネジメントコンソール上はディレクトリになるがトータルで1024バイトまで
under = 'aa/' + 'a' * 1020
just  = 'ab/' + 'b' * 1021
over  = 'ac/' + 'c' * 1022

Tempfile.create do |f|
  puts under.bytesize
  puts just.bytesize
  puts over.bytesize

  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{under}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{just}`
  puts `aws s3 cp #{f.path} s3://#{bucket_name}/#{over}`  # エラーになる
end
