# エラーの種類の一覧
$err_types = {
  NOT_FOUND: 'Not Fount',
  REQUIRE_FIELD: 'Require Field',
  VALID_ERR: 'Valid Err',
  DUPLICATE_NOT_ALLOWED: 'Duplicate Not Allowed',
  PROCESS_NOT_ALLOWED: 'Process Not Allowed',
  PROCESS_NOT_NECESSARY: 'Process Not Necessary'
}

# エラーの場合のオブジェクトを生成
def err_obj(status, type, msg: '', details: {})
  {
    # ステータスコード
    status: status,
    # エラーの種類
    type: type,
    # エラーメッセージ  
    msg: msg,
    # エラーの詳細
    details: details
  }
end
