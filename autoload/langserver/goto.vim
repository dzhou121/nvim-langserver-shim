function! langserver#goto#callback(id, data, event) abort
  call langserver#log#callback(a:id, a:data, a:event)

  if type(a:data) != type({})
    return
  endif

  if has_key(a:data, 'response')
    if empty(a:data['response']['result'])
      call langserver#log#log('warning', 'No definition found for: ' . string(a:data['request']), v:true)
      return
    endif

    if type(a:data['response']['result']) == type([])
      let l:parsed_data = a:data['response']['result'][0]
    elseif type(a:data['response']['result']) == type({})
      let l:parsed_data = a:data['response']['result']
    endif
  else
    return
  endif

  " {'data':
  "     {'textDocument/definition':
  "         [
  "             {'uri': 'file:///home/tj/go/src/github.com/sourcegraph/go-langserver/langserver/util.go',
  "              'range': {
  "                 'end': {'character': 29, 'line': 15},
  "                 'start': {'character': 23, 'line': 15}}
  "             }
  "         ]
  "      },
  "      'type': 'result'}
  call langserver#goto#goto_defintion(a:id, l:parsed_data['uri'], l:parsed_data['range'], {})
endfunction

function! langserver#goto#request(...) abort
  if a:0 > 0
    let l:sever_name = a:1
  else
    let l:server_name = langserver#util#get_lsp_id()
  endif

  call langserver#client#send(l:server_name, {
        \ 'method': 'textDocument/definition',
        \ 'params': {
          \ 'textDocument': langserver#util#get_text_document_identifier(l:server_name),
          \ 'position': langserver#util#get_position(),
          \ },
        \ })
endfunction

function! langserver#goto#goto_defintion(name, uri, range_dict, options) abort
  " TODO: Case sensitivity?
  if a:uri !=? langserver#util#get_uri(a:name, expand('%'))
    let l:file_name = langserver#util#get_filename(a:name, a:uri)
    let l:file_bufnr = bufnr(l:file_name)

    if l:file_bufnr > 0
      execute(':silent buffer ' . bufnr(l:file_name))
    else
      execute('silent edit ' . l:file_name)
    endif

    " Print an informative message
    file!
  endif


  " Functions to Handle moving around:
  " Saving:
  "     winsaveview / winrestview
  " Moving:
  "     cursor
  "           call cursor(
  "                 \ range['start']['line'],
  "                 \ range['start']['character'],
  "                 \ )
  "     normal <line>G<column>|
  " This keeps the jumplist intact.
  " echom printf('norm! %sG%s|',
  "       \ a:range_dict['start']['line'] + 1,
  "       \ a:range_dict['start']['character'] + 1,
  "       \ )
  let l:action = printf('norm! %sG%s|',
        \ a:range_dict['start']['line'] + 1,
        \ a:range_dict['start']['character'] + 1,
        \ )
  execute(l:action)

  return l:action
endfunction
