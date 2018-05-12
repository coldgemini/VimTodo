" File:        todo.txt.vim
" Description: Todo.txt filetype detection
" Author:      Leandro Freitas <freitass@gmail.com>
" License:     Vim license
" Website:     http://github.com/freitass/todo.txt-vim
" Version:     0.4

" We will use this to recreate our newlines later
let newline_place_holder= "MYNEWLINE_PLACE_HOLDER"
"We will use this to find the end of the data we are sorting as we reformat
let end_pointer= "MY_END_POINTER"

" Export Context Dictionary for unit testing {{{1
function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

function! todo#txt#__context__()
    return { 'sid': s:SID, 'scope': s: }
endfunction

" Functions {{{1
function! s:remove_priority()
    :s/^(\w)\s\+//ge
endfunction

function! s:get_current_date()
    return strftime('%Y-%m-%d')
endfunction

function! todo#txt#prepend_date()
    execute 'normal! I' . s:get_current_date() . ' '
endfunction

function! todo#txt#replace_date()
    let current_line = getline('.')
    if (current_line =~ '^\(([a-zA-Z]) \)\?\d\{2,4\}-\d\{2\}-\d\{2\} ') &&
                \ exists('g:todo_existing_date') && g:todo_existing_date == 'n'
        return
    endif
    execute 's/^\(([a-zA-Z]) \)\?\(\d\{2,4\}-\d\{2\}-\d\{2\} \)\?/\1' . s:get_current_date() . ' /'
endfunction

function! todo#txt#replace_due_date()
    let current_line = getline('.')
    if (current_line =~ '^\(([a-zA-Z]) \)\?D\d\{2,4\}-\d\{2\}-\d\{2\} ') &&
                \ exists('g:todo_existing_date') && g:todo_existing_date == 'n'
        return
    endif
    execute 's/^\(([a-zA-Z]) \)\?\(D\d\{2,4\}-\d\{2\}-\d\{2\} \)\?/\1D' . s:get_current_date() . ' /'
endfunction

function! todo#txt#mark_list_as_done()
    let l:linenum = line(".")
    call s:remove_priority()
    call todo#txt#prepend_date()
    silent execute 'normal! Ix '
    "if getline(".") =~ 
    let l:linenum = l:linenum + 1
    let current_line = getline(l:linenum)
    while current_line =~ '^\t'
        "execute 'normal! Ix '
        silent execute l:linenum . "s/^\t/\tx /"
        "silent execute 'normal!' . l:linenum . ' Ix '
        let l:linenum = l:linenum + 1
        let current_line = getline(l:linenum)
    endwhile
    "if current_line =~ '^\t'
        "execute 's/^/hahaha/'
    "endif
endfunction

function! todo#txt#mark_as_done()
    let l:linenum = line(".")
    let current_line = getline(l:linenum)
    let l:linenum = l:linenum + 1
    let next_line = getline(l:linenum)
    if next_line =~ '^\t' && current_line =~ '^\w'
        call todo#txt#mark_list_as_done()
    else
        call s:remove_priority()
        call todo#txt#prepend_date()
        execute 'normal! Ix '
    endif
endfunction

function! todo#txt#mark_all_as_done()
    :g!/^x /:call todo#txt#mark_as_done()
endfunction

function! s:append_to_file(file, lines)
    let l:lines = []

    " Place existing tasks in done.txt at the beggining of the list.
    if filereadable(a:file)
        call extend(l:lines, readfile(a:file))
    endif

    " Append new completed tasks to the list.
    call extend(l:lines, a:lines)

    " Write to file.
    call writefile(l:lines, a:file)
endfunction

function! todo#txt#remove_completed()
    " Check if we can write to done.txt before proceeding.

    let l:target_dir = expand('%:p:h')
    let l:todo_file = expand('%:p')
    let l:done_file = substitute(substitute(l:todo_file, 'todo.txt$', 'done.txt', ''), 'Todo.txt$', 'Done.txt', '')
    if !filewritable(l:done_file) && !filewritable(l:target_dir)
        echoerr "Can't write to file 'done.txt'"
        return
    endif

    let l:completed = []
    :g/^x /call add(l:completed, getline(line(".")))|d
    call s:append_to_file(l:done_file, l:completed)
endfunction

function! todo#txt#sort_by_context() range
    "execute a:firstline . "," . a:lastline . "sort /\\(^\\| \\)\\zs@[^[:blank:]]\\+/ r"
    let l:context_regex = "\\(^\\| \\)\\zs@[^[:blank:]]\\+"
    silent execute a:lastline ."s/".'$'."/". g:end_pointer ."/"
    " Replace all newlines with our placeholder
    silent execute a:firstline . "," . a:lastline ."s/".'\n\t'."/". g:newline_place_holder."/g"
    let tmp_last_line = search(g:end_pointer)
    "silent execute a:firstline . "," . tmp_last_line . "sort /" . l:date_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "sort /" . l:context_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "g!/" . l:context_regex . "/m" . tmp_last_line
    silent execute a:firstline . "," . tmp_last_line ."s/". g:newline_place_holder ."/". "\r\t" ."/g"
    let tmp_last_line2 = search(g:end_pointer)
    silent execute tmp_last_line2 ."s/". g:end_pointer ."/" . "/g"
endfunction

function! todo#txt#sort_by_project() range
    "execute a:firstline . "," . a:lastline . "sort /\\(^\\| \\)\\zs+[^[:blank:]]\\+/ r"
    let l:project_regex = "\\(^\\| \\)\\zs+[^[:blank:]]\\+"
    silent execute a:lastline ."s/".'$'."/". g:end_pointer ."/"
    " Replace all newlines with our placeholder
    silent execute a:firstline . "," . a:lastline ."s/".'\n\t'."/". g:newline_place_holder."/g"
    let tmp_last_line = search(g:end_pointer)
    "silent execute a:firstline . "," . tmp_last_line . "sort /" . l:date_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "sort /" . l:project_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "g!/" . l:project_regex . "/m" . tmp_last_line
    silent execute a:firstline . "," . tmp_last_line ."s/". g:newline_place_holder ."/". "\r\t" ."/g"
    let tmp_last_line2 = search(g:end_pointer)
    silent execute tmp_last_line2 ."s/". g:end_pointer ."/" . "/g"
endfunction

function! todo#txt#sort_by_date() range
    let l:date_regex = "\\d\\{2,4\\}-\\d\\{2\\}-\\d\\{2\\}"
    "execute a:firstline . "," . a:lastline . "sort /" . l:date_regex . "/ r"
    "execute a:firstline . "," . a:lastline . "g!/" . l:date_regex . "/m" . a:lastline
    silent execute a:lastline ."s/".'$'."/". g:end_pointer ."/"
    " Replace all newlines with our placeholder
    silent execute a:firstline . "," . a:lastline ."s/".'\n\t'."/". g:newline_place_holder."/g"
    let tmp_last_line = search(g:end_pointer)
    silent execute a:firstline . "," . tmp_last_line . "sort /" . l:date_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "g!/" . l:date_regex . "/m" . tmp_last_line
    silent execute a:firstline . "," . tmp_last_line ."s/". g:newline_place_holder ."/". "\r\t" ."/g"
    let tmp_last_line2 = search(g:end_pointer)
    silent execute tmp_last_line2 ."s/". g:end_pointer ."/" . "/g"
endfunction

function! todo#txt#sort_by_due_date() range
    "let l:date_regex = "due:\\d\\{2,4\\}-\\d\\{2\\}-\\d\\{2\\}"
    let l:date_regex = "D\\d\\{2,4\\}-\\d\\{2\\}-\\d\\{2\\}"

    silent execute a:lastline ."s/".'$'."/". g:end_pointer ."/"
    " Replace all newlines with our placeholder
    silent execute a:firstline . "," . a:lastline ."s/".'\n\t'."/". g:newline_place_holder."/g"
    let tmp_last_line = search(g:end_pointer)
    silent execute a:firstline . "," . tmp_last_line . "sort /" . l:date_regex . "/ r"
    silent execute a:firstline . "," . tmp_last_line . "g!/" . l:date_regex . "/m" . tmp_last_line
    silent execute a:firstline . "," . tmp_last_line ."s/". g:newline_place_holder ."/". "\r\t" ."/g"
    let tmp_last_line2 = search(g:end_pointer)
    silent execute tmp_last_line2 ."s/". g:end_pointer ."/" . "/g"
endfunction

" Increment and Decrement The Priority
:set nf=octal,hex,alpha

function! todo#txt#prioritize_increase()
    normal! 0f)h
endfunction

function! todo#txt#prioritize_decrease()
    normal! 0f)h
endfunction

function! todo#txt#prioritize_add(priority)
    " Need to figure out how to only do this if the first visible letter in a line is not (
    :call todo#txt#prioritize_add_action(a:priority)
endfunction

function! todo#txt#prioritize_add_action(priority)
    execute 's/^\(([a-zA-Z]) \)\?/(' . a:priority . ') /'
endfunction

" Modeline {{{1
" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
