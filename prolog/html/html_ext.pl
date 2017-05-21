:- module(
  html_ext,
  [
    deck//2,               % :Card_1, +Items
    deck//3,               % +Attrs, :Card_1, +Items
    ellipsis//2,           % +Str, +MaxLen
    external_link_icon//1, % +Uri
    flag_icon//1,          % +LTag
    html_call//1,          % :Html_0
    html_call//2,          % :Html_1, +Arg1
    html_date_time//1,     % +Something
    html_date_time//2,     % +Something, +Opts
    html_maplist//2,       % :Html_1, +Args1
    html_thousands//1,     % +Integer
    image//1,              % +Spec
    image//2,              % +Spec, +Attrs
    link//1,               % +Pair
    link//2,               % +Attrs, +Pair
    mail_icon//1,          % +Uri
    meta_authors//0,
    meta_description//1,   % +Desc
    navbar//3,             % :Brand_0, :Menu_0, :Right_0
    open_graph//2,         % +Key, +Value
    tooltip//2,            % +String, :Html_0
    twitter_follow_img//0
  ]
).
:- reexport(library(http/html_head)).
:- reexport(library(http/html_write)).
:- reexport(library(http/js_write)).

/** <module> HTML extensions

Besides the reusable HTML snippets provided by this module, raw HTML
can always be included by using the following quasi-quoting notation:

```
html({|html||...|}).
```

@author Wouter Beek
@version 2017/04-2017/05
*/

:- use_module(library(apply)).
:- use_module(library(date_time)).
:- use_module(library(debug)).
:- use_module(library(html/html_date_time_human)).
:- use_module(library(html/html_date_time_machine)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_resource)).
:- use_module(library(http/jquery)).
:- use_module(library(lists)).
:- use_module(library(settings)).
:- use_module(library(uri/uri_ext)).

% jQuery
:- set_setting(jquery:version, '3.2.1.min').

:- dynamic
    html:author/1,
    nlp:nlp_string0/3.

:- html_meta
    deck(3, +, ?, ?),
    deck(+, 3, +, ?, ?),
    html_call(html, ?, ?),
    html_call(3, +, ?, ?),
    html_maplist(3, +, ?, ?),
    navbar(html, html, html, ?, ?),
    tooltip(+, html, ?, ?),
    twitter_follow0(+, html, ?, ?).

% Bootstrap
:- if(debugging(css(bootstrap))).
  :- html_resource(
       css(bootstrap),
       [requires([css('bootstrap.css')]),virtual(true)]
     ).
:- else.
  :- html_resource(
       css(bootstrap),
       [requires([css('bootstrap.min.css')]),virtual(true)]
     ).
:- endif.
:- if(debugging(js(bootstrap))).
  :- html_resource(
       js(bootstrap),
       [
         ordered(true),
         requires([jquery,tether,js('bootstrap.js')]),
         virtual(true)
       ]
     ).
:- else.
  :- html_resource(
       js(bootstrap),
       [
         ordered(true),
         requires([jquery,tether,js('bootstrap.min.js')]),
         virtual(true)
       ]
     ).
:- endif.
:- html_resource(
     bootstrap,
     [requires([css(bootstrap),js(bootstrap)]),virtual(true)]
   ).

% FontAwesome
:- if(debugging(css('font-awesome'))).
  :- html_resource(
       css('font-awesome'),
       [requires([css('font-awesome-4.7.0.css')]),virtual(true)]
     ).
:- else.
  :- html_resource(
       css('font-awesome'),
       [requires([css('font-awesome-4.7.0.min.css')]),virtual(true)]
     ).
:- endif.
:- html_resource(
     'font-awesome',
     [requires([css('font-awesome')]),virtual(true)]
   ).

% HTML extensions
:- html_resource(
     html_ext,
     [
       ordered(true),
       requires([bootstrap,'font-awesome',css('html_ext.css')]),
       virtual(true)
     ]
   ).

% Tether
:- if(debugging(js(tether))).
  :- html_resource(
       js(tether),
       [requires([js('tether-1.3.3.js')]),virtual(true)]
     ).
:- else.
  :- html_resource(
       js(tether),
       [requires([js('tether-1.3.3.min.js')]),virtual(true)]
     ).
:- endif.
:- html_resource(
     tether,
     [requires([js(tether)]),virtual(true)]
   ).

:- multifile
    html:author/1,
    nlp:nlp_string0/3.

nlp:nlp_string0(en, follow_us_on_x, "Follow us on ~s").
nlp:nlp_string0(nl, follow_us_on_x, "Volg ons op ~s").

:- setting(
     html:twitter_profile,
     any,
     _,
     "Optional Twitter profile name."
   ).





%! deck(:Card_1, +Items)// is det.
%! deck(+Attrs, :Card_1, +Items)// is det.

deck(Card_1, L) -->
  deck([], Card_1, L).


deck(Attrs1, Card_1, L) -->
  {merge_attrs([class=['card-columns']], Attrs1, Attrs2)},
  html(div(Attrs2, \html_maplist(Card_1, L))).



%! ellipsis(+Str, +MaxLen)// is det.

ellipsis(Str, MaxLen) -->
  {string_ellipsis(Str, MaxLen, Ellipsis)},
  ({Str == Ellipsis} -> html(Str) ; tooltip(Str, Ellipsis)).



%! external_link_icon(+Uri)// is det.

external_link_icon(Uri) -->
  html(a([href=Uri,target='_blank'], \icon(external_link))).



%! flag_icon(+LTag)// is det.

flag_icon(LTag) -->
  {
    file_name_extension(LTag, svg, File),
    directory_file_path(flag_4x3, File, Path)
  },
  html(span(class=[label,'label-primary'], [\flag_icon_img(Path)," ",LTag])).


flag_icon_img(Path) -->
  {
    absolute_file_name(img(Path), _, [access(read)]), !,
    http_absolute_location(img(Path), Location)
  },
  html(span(class='flag-icon', img(src=Location))).
flag_icon_img(_) --> [].



%! html_call(:Html_0)// is det.
%! html_call(:Html_1, +Arg1)// is det.

html_call(Html_0, X, Y) :-
  call(Html_0, X, Y).


html_call(Html_1, Arg1, X, Y) :-
  call(Html_1, Arg1, X, Y).



%! html_date_time(+Something)// is det.
%! html_date_time(+Something, +Opts)// is det.
%
% Generates human- and machine-readable HTML for date/times.
%
% The following options are supported:
%
%   * ltag(+oneof([en,nl])
%
%     The language tag denoting the natural language that is used to
%     display human-readable content in.  The default is `en`.
%
%   * masks(+list(atom))
%
%     The following masks are supported: `none`, `year`, `month`,
%     `day`, `hour`, `minute`, `second`, `offset`.  The default is
%     `[]`.
%
%   * month_abbr(+boolean)
%
%     Whether the human-readable representation of month names should
%     use abbreviated names or not.  The default is `false`.

html_date_time(Something) -->
  {current_ltag(LTag)}, !,
  html_date_time(Something, _{ltag: LTag}).


html_date_time(Something, Opts) -->
  {
    something_to_date_time(Something, DT),
    html_machine_date_time(DT, MachineString),
    get_dict(masks, Opts, [], Masks),
    date_time_masks(Masks, DT, MaskedDT)
  },
  html(time(datetime=MachineString, \html_human_date_time(MaskedDT, Opts))).



%! html_maplist(:Html_1, +Args1) .

html_maplist(_, []) --> !, [].
html_maplist(Html_1, [H|T]) -->
  html_call(Html_1, H),
  html_maplist(Html_1, T).


%! html_thousands(+Integer)// is det.

html_thousands(inf) --> !,
  html("∞").
html_thousands(Integer) -->
  html("~:D"-[Integer]).



%! icon(+Name)// is det.

% @tbd Use file `img/pen.svg' instead.
icon(pen) --> !,
  html(
    svg([width=14,height=14,viewBox=[0,0,300,300]],
      path([fill='#777777',d='M253 123l-77-77 46-46 77 77-46 46zm-92-61l77 77s-35 16-46 77c-62 62-123 62-123 62s-24 36-46 15l93-94c55 12 50-39 37-52s-62-21-52 37L7 277c-21-21 15-46 15-46s0-62 62-123c51-5 77-46 77-46z'], [])
    )
  ).
icon(Name) -->
  {icon_class(Name, Class)},
  html(span(class([fa,Class]), [])).



%! icon_class(+Name, -Class, -Title) is det.

icon_class(Name, Class) :-
  icon_class_title(Name, Class, _).



%! icon_class_title(+Name, -Class, -Title) is det.

icon_class_title(Name, Class, Title) :-
  icon_table(Name, ClassPostfix, Title),
  atomic_list_concat([fa,ClassPostfix], -, Class).



%! icon_table(?Name, ?Class, ?Title) is nondet.

% CRUD = Create, Read, Update, Delete.
icon_table(cancel,         eraser,          "Cancel").
icon_table(copy,           copy,            "Copy").
icon_table(create,         pencil,          "Create").
icon_table(delete,         trash,           "Delete").
icon_table(download,       download,        "Download").
icon_table(external_link,  'external-link', "Follow link").
icon_table(internal_link,  link,            "Follow link").
icon_table(mail,           envelope,        "Send email").
icon_table(tag,            tag,             "").
icon_table(tags,           tags,            "").
icon_table(time,           'clock-o',       "Date/time").
icon_table(user,           user,            "Log me in").
icon_table(vote_down,     'thumbs-o-down',  "Vote up").
icon_table(vote_up,       'thumbs-o-up',    "Vote down").
icon_table(web,            globe,           "Visit Web site").



%! image(+Spec)// is det.
%! image(+Spec, +Attrs)// is det.

image(Spec) -->
  image(Spec, []).


image(Spec, Attrs1) -->
  {
    uri_specification(Spec, Uri),
    merge_attrs(Attrs1, [src=Uri], Attrs2)
  },
  html(img(Attrs2, [])).



%! link(+Pair)// is det.
%! link(+Attrs, +Pair)// is det.
%
% Pair is of the form `Rel-Uri`, where Uri is based on Spec.

link(Pair) -->
  link([], Pair).


link(Attrs1, Rel-Spec) -->
  {
    uri_specification(Spec, Uri),
    merge_attrs(Attrs1, [href=Uri,rel=Rel], Attrs2)
  },
  html(link(Attrs2, [])).



%! mail_icon(+Uri)// is det.

mail_icon(Uri) -->
  external_link(Uri, [property='foaf:mbox'], [" ",\icon(mail)]).



%! meta_authors// is det.

meta_authors -->
  {
    findall(String, html:author(String), Strings),
    atomics_to_string(Strings, ",", String)
  },
  meta(author, String).



%! meta_description(+String)// is det.

meta_description(String) -->
  meta(description, String).



%! navbar(:Brand_0, :Menu_0, :Right_0)// is det.

navbar(Brand_0, Menu_0, Right_0) -->
  html([
    nav([
      class=[
        'bg-faded',
        'fixed-top',
        navbar,
        'navbar-light',
        'navbar-toggleable-md'
      ]
    ], [
        \hamburger,
        a([class='navbar-brand',href='/'], Brand_0),
        div([class=[collapse,'navbar-collapse'],id=target], [
          ul(class=['navbar-nav','mr-auto'], Menu_0),
          ul(class='navbar-nav', Right_0)
        ])
      ]
    )
  ]).

hamburger -->
  html(
    button([
      'aria-controls'='target#',
      'aria-expanded'=false,
      'aria-label'="Toggle navigation",
      class=[collapsed,'navbar-toggler','navbar-toggler-right'],
      'data-target'='target#',
      'data-toggle'=collapse,
      type=button
    ], span(class='navbar-toggler-icon', []))
  ).



%! open_graph(+Key, +Value)// is det.

open_graph(Key0, Val) -->
  {atomic_list_concat([og,Key0], :, Key)},
  html(meta([property=Key,content=Val], [])).



%! tooltip(+String, :Html_0)// is det.

tooltip(String, Html_0) -->
  html(span(['data-toggle'=tooltip,title=String], Html_0)).



%! twitter_follow_img// is det.

twitter_follow_img -->
  {
    setting(html:twitter_profile, User),
    ground(User)
  }, !,
  {nlp_string(follow_us_on_x, ["Twitter"], String)},
  tooltip(String, \twitter_follow0(User, \twitter_img0)).  
twitter_follow_img --> [].

twitter_follow0(User, Html_0) -->
  {twitter_user_uri0(User, Uri)},
  html(a(href=Uri, Html_0)).

twitter_img0 -->
  image(img('twitter.png'), [alt="Twitter"]).

twitter_user_uri0(User, Uri) :-
  uri_comps(Uri, uri(https,'twitter.com',[User],_,_)).





% HELPERS %

%! merge_attrs(+Attrs1, +Attrs2, -Attrs3) is det.
%
% Merge two lists of HTML attributes into one.

merge_attrs([], L, L) :- !.
% HTTP attribute with (possibly) multiple values.
merge_attrs([Key=Val1|T1], L2a, [Key=Val3|T3]):-
  attr_multi_value(Key),
  selectchk(Key=Val2, L2a, L2b), !,
  maplist(ensure_list, [Val1,Val2], [Val1L,Val2L]),
  append(Val1L, Val2L, ValL),
  sort(ValL, Val3),
  merge_attrs(T1, L2b, T3).
% HTTP attribute with a single value.
merge_attrs([Key=_|T1], L2a, [Key=Val2|T3]) :-
  selectchk(Key=Val2, L2a, L2b), !,
  merge_attrs(T1, L2b, T3).
merge_attrs([H|T1], L2, [H|T3]):-
  merge_attrs(T1, L2, T3).

attr_multi_value(class).

ensure_list(L, L) :-
  is_list(L), !.
ensure_list(Elem, [Elem]).



%! meta(+Name, +Content)// is det.

meta(Name, Content) -->
  html(meta([name=Name,content=Content], [])).



%! uri_specification(+Spec, -Uri) is det.
%
% Allows a URI to be specified in the following ways:
%
%   - link_to_id(<HANDLE-ID>)
%
%   - link_to_id(<HANDLE-ID>,<QUERY>)
%
%   - Compound terms processed by http_absolute_location/3
%
%   - atoms
%
% Whenever possible, the URI is abbreviated in case its schema, host
% and port are the local schema, host and port.

uri_specification(link_to_id(HandleId), Uri2) :- !,
  http_link_to_id(HandleId, [], Uri1),
  uri_remove_host(Uri1, Uri2).
% @tbd
%uri_specification(link_to_id(HandleId,Query0), Uri2) :- !,
%  maplist(rdf_query_term, Query0, Query), %HACK
%  http_link_to_id(HandleId, Query, Uri1),
%  uri_remove_host(Uri1, Uri2).
uri_specification(Spec, Uri2) :-
  http_absolute_location(Spec, Uri1, []),
  uri_remove_host(Uri1, Uri2).
