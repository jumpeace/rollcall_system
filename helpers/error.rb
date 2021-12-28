$err_types = {
  NOT_FOUND: 'Not Fount',
  REQUIRE_FIELD: 'Require Field',
  VALID_ERR: 'Valid Err',
  DUPLICATE_NOT_ALLOWED: 'Duplicate Not Allowed',
  PROCESS_NOT_ALLOWED: 'Process Not Allowed',
  PROCESS_NOT_NECESSARY: 'Process Not Necessary'
}

def err_obj(status, type, msg: '', details: {})
  {
    status: status,
    type: type,
    msg: msg,
    details: details
  }
end
