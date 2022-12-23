":source :call filename#funcname() 現在のパスからパスセパレータを取得しています。
" ここはそれほど重要ではないので、おまじないと考えておいてください。
" 詳しく知りたい方は`:h fnamemodify()`を参照してください。
let s:sep = fnamemodify('.', ':p')[-1:]

function! session#create_session(file) abort
  " SessionCreateの引数をfileで受け取れるようにします。
  " join()でセッションファイル保存先へのフルパスを生成し、mksession!でセッションファイルを作成します。
  
  echo g:session_path
  execute 'mksession!' join([g:session_path, a:file], s:sep)

  " redrawで画面を再描画してメッセージを出力します。
  redraw
  echo 'session.vim: created'
endfunction

function! session#load_session(file) abort
  " `:source`で渡されるセッションファイルをロードします。
  execute 'source' join([g:session_path, a:file], s:sep)
endfunction

" エラーメッセージ(赤)を出力する関数
" echohl でコマンドラインの文字列をハイライトできます。詳細は:h echohlを参照してください
function! s:echo_err(msg) abort
  echohl ErrorMsg
  echomsg 'session.vim:' a:msg
  echohl None
endfunction

" 結果 => ['file1', 'file2', ...]
function! s:files() abort
  " g:session_pat hからセッションファイルの保存先を取得します
  " g: はグローバルな辞書変数なので get() を使用して指定したキーの値を取得できます
  let session_path = get(g:, 'session_path', '')

  " g:session_pathが設定されていない場合はエラーメッセージを出し空のリストを返します
  if session_path is# ''
    call s:echo_err('g:session_path is empty')
    return []
  endif

  " file という引数を受けとり、そのファイルがディレクトリでなければ1を返すLambdaです
  let Filter = { file -> !isdirectory(session_path . s:sep . file) }

  " readdir の第2引数に Filter を使用することでファイルだけが入ったリストを取得できます
  return readdir(session_path, Filter)
endfunction

" セッション一覧を表示するバッファ名
let s:session_list_buffer = 'SESSIONS'

function! session#sessions() abort
  let files = s:files()
  if empty(files)
    return
  endif

  " バッファが存在している場合
  if bufexists(s:session_list_buffer)
    " バッファがウィンドウに表示されている場合は`win_gotoid`でウィンドウに移動します
    let winid = bufwinid(s:session_list_buffer)
    if winid isnot# -1
      call win_gotoid(winid)

    " バッファがウィンドウに表示されていない場合は`sbuffer`で新しいウィンドウを作成してバッファを開きます
    else
      execute 'sbuffer' s:session_list_buffer
    endif

  else
    " バッファが存在していない場合は`new`で新しいバッファを作成します
    execute 'new' s:session_list_buffer

    " バッファの種類を指定します
    " ユーザが書き込むことはないバッファなので`nofile`に設定します
    " 詳細は`:h buftype`を参照してください
    set buftype=nofile

    " 1. セッション一覧のバッファで`q`を押下するとバッファを破棄
    " 2. `Enter`でセッションをロード
    " の2つのキーマッピングを定義します。
    "
    " <C-u>と<CR>はそれぞれコマンドラインでCTRL-uとEnterを押下した時の動作になります
    " <buffer>は現在のバッファにのみキーマップを設定します
    " <silent>はキーマップで実行されるコマンドがコマンドラインに表示されないようにします
    " <Plug>という特殊な文字を使用するとキーを割り当てないマップを用意できます
    " ユーザはこのマップを使用して自分の好きなキーマップを設定できます
    "
    " \ は改行するときに必要です
    nnoremap <silent> <buffer>
      \ <Plug>(session-close)
      \ :<C-u>bwipeout!<CR>

    nnoremap <silent> <buffer>
      \ <Plug>(session-open)
      \ :<C-u>call session#load_session(trim(getline('.')))<CR>

    " <Plug>マップをキーにマッピングします
    " `q` は最終的に :<C-u>bwipeout!<CR>
    " `Enter` は最終的に :<C-u>call session#load_session()<CR>
    " が実行されます
    nmap <buffer> q <Plug>(session-close)
    nmap <buffer> <CR> <Plug>(session-open)
  endif

  " セッションファイルを表示する一時バッファのテキストをすべて削除して、取得したファイル一覧をバッファに挿入します
  %delete _
  call setline(1, files)
endfunction
