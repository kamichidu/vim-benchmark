"=============================================================================
" Benchmarking Tool for Vim script
"
" File    : autoload/benchmark.vim
" Author  : h1mesuke <himesuke+vim@gmail.com>
" Updated : 2012-04-13
" Version : 0.0.2
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:PRECISION = 6
let s:benchmarker = {}

function! s:benchmarker.run(...) abort
    if !(has('reltime') && has('float'))
        throw "benchmark: +reltime and +float features are required."
    endif
    echomsg "Benchmark: " . self.__caption__
    let bmfuncs = s:get_bmfuncs(self)
    let ntrials = (a:0 ? a:1 : 1)
    let results = {}
    for i in range(ntrials)
        for func in bmfuncs
            let result = {'i': i + 1}
            try
                let start_time = reltime()
                let retval = call(self[func], [], self)
                let result.duration = str2float(reltimestr(reltime(start_time)))
                if s:is_sample(retval)
                    let result.sample = retval
                endif
            catch
                let result.error = v:exception
            finally
                let results[func] = get(results, func, []) + [result]
            endtry
            unlet! retval
        endfor
    endfor
    call s:print_report(results)
endfunction

"
" Memo ~
"
" results
" ---
" bmfunc: [
"   duration: 0.0
"   error:    ''
"   sample:   ???
" ]
"
function! s:print_report(results)
    let data= {'body': []}
    let bmfuncs = keys(a:results)

    for bmfunc in bmfuncs
        let result= a:results[bmfunc]

        let durations= map(copy(result), 'get(v:val, "duration", "")')

        let data.body+= [[bmfunc] + durations]
    endfor

    let data.header= ['']
    for i in range(len(get(data.body, 0, [''])) - 1)
        let data.header+= ['Trial #' . (i + 1)]
    endfor

    echomsg ''
    for row in split(s:tabular(data), "\n")
        echomsg row
    endfor
    echomsg ''
    call s:print_summary(a:results)
    echomsg ''
    call s:print_error(a:results)
endfunction

function! s:print_error(results)
    echomsg 'Error report:'
    for bmfunc in keys(a:results)
        let errors= filter(copy(a:results[bmfunc]), 'has_key(v:val, "error")')

        if !empty(errors)
            echomsg '  ' . bmfunc
            for result in errors
                echomsg '    - Trial #' . result.i . ' - ' . result.error
            endfor
        endif
    endfor
endfunction

function! s:print_summary(results)
    echomsg 'Statistic report:'
    for bmfunc in keys(a:results)
        let durations= map(filter(copy(a:results[bmfunc]), 'has_key(v:val, "duration")'), 'v:val.duration')
        let mean1= s:compute_mean(durations)
        let sd1= s:compute_standard_deviation(mean1, durations)
        let samples= s:remove_noise(durations)
        let mean2= s:compute_mean(samples)
        let sd2= s:compute_standard_deviation(mean2, samples)

        echomsg '  ' . bmfunc
        echomsg '    - Mean       ' . printf('%f', mean2)
        echomsg '    - SD         ' . printf('%f', sd2)
        echomsg '    - Dirty Mean ' . printf('%f', mean1)
        echomsg '    - Dirty SD   ' . printf('%f', sd1)
    endfor
endfunction

"
" data
" ---
" header: []
" body: [[]]
" footer: []
"
function! s:tabular(data)
    let data= deepcopy(a:data)
    let max_columns= max([
    \   len(get(data, 'header', [])),
    \   max(map(copy(data), 'len(v:val)')),
    \   len(get(data, 'footer', [])),
    \])

    let rows= []

    if has_key(data, 'header')
        let rows+= [data.header + map(range(max_columns - len(data.header)), '""')]
    endif
    if has_key(data, 'body')
        for row in data.body
            let rows+= [row + map(range(max_columns - len(row)), '""')]
        endfor
    endif
    if has_key(data, 'footer')
        let rows+= [data.footer + map(range(max_columns - len(data.footer)), '""')]
    endif

    let sizes= []
    for cidx in range(max_columns)
        let width= 0
        for row in rows
            let width= max([strlen(s:ensure_string(row[cidx])), width])
        endfor
        let sizes+= [width]
    endfor

    " start to stringify
    let separator= '+' . join(map(copy(sizes), 'repeat("-", v:val + 2)'), '+') . '+'
    let table= [separator]
    let virgin= 1
    for row in rows
        let line= []
        for cidx in range(len(row))
            let line+= [s:align(sizes[cidx], row[cidx])]
        endfor
        let table+= ['| ' . join(line, ' | ') . ' |']
        if virgin
            let table+= [separator]
            let virgin= 0
        endif
    endfor
    let table+= [separator]

    return join(table, "\n")
endfunction

function! s:align(width, expr)
    if type(a:expr) == type(0.0) || type(a:expr) == type(0)
        return printf('% *s', a:width, s:ensure_string(a:expr))
    else
        return printf('%-*s', a:width, s:ensure_string(a:expr))
    endif
endfunction

function! s:ensure_string(expr)
    if type(a:expr) == type('')
        return a:expr
    elseif type(a:expr) == type(0.0)
        return printf('%f', a:expr)
    elseif type(a:expr) == type(0)
        return printf('%d', a:expr)
    elseif type(a:expr) == type([]) || type(a:expr) == type({})
        return string(a:expr)
    else
        throw 'Unsupported type'
    endif
endfunction

function! s:compute_mean(elements)
    let sum= 0.0
    for element in a:elements
        let sum+= element
    endfor
    return sum / len(a:elements)
endfunction

function! s:compute_variance(mean, elements)
    let v= 0.0
    for element in a:elements
        let v+= pow(element - a:mean, 2)
    endfor
    return v / len(a:elements)
endfunction

function! s:compute_standard_deviation(mean, elements)
    return pow(s:compute_variance(a:mean, a:elements), 0.5)
endfunction

function! s:remove_noise(elements)
    let mean= s:compute_mean(a:elements)
    " standard variation
    let s= s:compute_standard_deviation(mean, a:elements)

    return filter(copy(a:elements), 'abs(mean - v:val) <= s')
endfunction

function! s:get_bmfuncs(bm)
    let type_func = type(function('tr'))
    let is_funcref = 'type(a:bm[v:val]) == type_func'
    let is_bmfunc = 'v:val != "run" && v:val !~ "^_"'
    return filter(keys(a:bm), is_funcref . ' && ' . is_bmfunc)
endfunction

function! s:is_sample(value)
    return (type(a:value) != type(0) || a:value != 0)
endfunction

function! s:compare_used(item1, item2)
    let used1 = a:item1[1].used
    let used2 = a:item2[1].used
    return (used1 == used2 ? 0 : (used1 > used2 ? 1 : -1))
endfunction

function! benchmark#new(...)
    let bm = copy(s:benchmarker)
    let bm.__caption__ = (a:0 ? a:1 : "")
    return bm
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
