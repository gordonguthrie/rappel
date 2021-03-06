// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket


var menu_buttons = document.getElementsByClassName("menu-item");

var menuClick = function(e) {
	var pressedID = e.originalTarget.getAttribute("data-menu-controlled");
    var menu_items = document.getElementsByClassName("menu-controlled");
	Array.from(menu_items).forEach(function(menu_item) {
        menu_item.classList.add("hidden");
    });
    var pressed = document.getElementById(pressedID);
    pressed.classList.remove("hidden");

};

Array.from(menu_buttons).forEach(function(menu_button) {
      menu_button.addEventListener('click', menuClick);
    });

// Complete APL menu nicked from https://abrudz.github.io/lb/apl

// not all symbols are implemented yet :-(

;(_=>{
let hc={'<':'&lt;','&':'&amp;',"'":'&apos;','"':'&quot;'},he=x=>x.replace(/[<&'"]/g,c=>hc[c]) //html chars and escape fn
,tcs='<-←xx×/\\×:-÷*O⍟[-⌹-]⌹OO○77⌈FF⌈ll⌊LL⌊T_⌶II⌶|_⊥TT⊤-|⊣|-⊢=/≠L-≠<=≤<_≤>=≥>_≥==≡=_≡7=≢L=≢vv∨^^∧^~⍲v~⍱^|↑v|↓((⊂cc⊂(_⊆c_⊆))⊃[|⌷|]⌷A|⍋V|⍒ii⍳i_⍸ee∊e_⍷'+
'uu∪UU∪nn∩/-⌿\\-⍀,-⍪rr⍴pp⍴O|⌽O-⊖O\\⍉::¨""¨~:⍨~"⍨*:⍣*"⍣oo∘o:⍤o"⍤O:⍥O"⍥[\'⍞\']⍞[]⎕[:⍠:]⍠[=⌸=]⌸[<⌺>]⌺o_⍎oT⍕o-⍕<>⋄^v⋄on⍝->→aa⍺ww⍵VV∇v-∇--¯0~⍬'+
'AA∆^-∆A_⍙^=⍙[?⍰?]⍰:V⍢∇"⍢||∥ox¤)_⊇_)⊇V~⍫\'\'`'
,lbs=['←←\nASSIGN',' ','++\nconjugate\nplus','--\nnegate\nminus','××\ndirection\ntimes','÷÷\nreciprocal\ndivide','**\nexponential\npower','⍟⍟\nnatural logarithm\nlogarithm',
'⌹⌹\nmatrix inverse\nmatrix divide','○○\npi times\ncircular','!!\nfactorial\nbinomial','??\nroll\ndeal',' ','||\nmagnitude\nresidue',
'⌈⌈\nceiling\nmaximum','⌊⌊\nfloor\nminimum','⊥⊥\ndecode','⊤⊤\nencode','⊣⊣\nsame\nleft','⊢⊢\nsame\nright',' ','==\nequal','≠≠\nunique mask\nnot equal',
'≤≤\nless than or equal to','<<\nless than','>>\ngreater than','≥≥\ngreater than or equal to','≡≡\ndepth\nmatch','≢≢\ntally\nnot match',' ','∨∨\ngreatest common divisor/or',
'∧∧\nlowest common multiple/and','⍲⍲\nnand','⍱⍱\nnor',' ','↑↑\nmix\ntake','↓↓\nsplit\ndrop','⊂⊂\nenclose\npartioned enclose','⊃⊃\nfirst\npick','⊆⊆\nnest\npartition','⌷⌷\nmaterialise\nindex','⍋⍋\ngrade up\ngrades up',
'⍒⍒\ngrade down\ngrades down',' ','⍳⍳\nindices\nindices of','⍸⍸\nwhere\ninterval index','∊∊\nenlist\nmember of','⍷⍷\nfind','∪∪\nunique\nunion','∩∩\nintersection','~~\nnot\nwithout',' ',
'//\nreplicate\nReduce','\\\\\n\expand\nScan','⌿⌿\nreplicate first\nReduce First','⍀⍀\nexpand first\nScan First',' ',',,\nenlist\ncatenate/laminate',
'⍪⍪\ntable\ncatenate first/laminate','⍴⍴\nshape\nreshape','⌽⌽\nreverse\nrotate','⊖⊖\nreverse first\nrotate first',
'⍉⍉\ntranspose\nreorder axes',' ','¨¨\neach','⍨⍨\nconstant\nself\nswap','⍣⍣\nrepeat\nuntil','..\nouter product (∘.)\ninner product',
'∘∘\nouter product (∘.)\nbind\nbeside','⍤⍤\nrank\natop','⍥⍥\nover','@@\nat',' ','⍞⍞\nSTDIN\nSTDERR','⎕⎕\nEVALUATED STDIN\nSTDOUT\nSYSTEM NAME PREFIX','⍠⍠\nvariant',
'⌸⌸\nindex key\nkey','⌺⌺\nstencil','⌶⌶\nI-beam','⍎⍎\nexecute','⍕⍕\nformat',' ','⋄⋄\nSTATEMENT SEPARATOR','⍝⍝\nCOMMENT','→→\nABORT\nBRANCH','⍵⍵\nRIGHT ARGUMENT\nRIGHT OPERAND (⍵⍵)','⍺⍺\nLEFT ARGUMENT\nLEFT OPERAND (⍺⍺)',
'∇∇\nrecursion\nrecursion (∇∇)','&&\nspawn',' ','¯¯\nNEGATIVE','⍬⍬\nEMPTY NUMERIC VECTOR','∆∆\nIDENTIFIER CHARACTER','⍙⍙\nIDENTIFIER CHARACTER']
,bqk=' =1234567890-qwertyuiop\\asdfghjk∙l;\'zxcvbnm,./`[]+!@#$%^&*()_QWERTYUIOP|ASDFGHJKL:"ZXCVBNM<>?~{}'.replace(/∙/g,'')
,bqv='`÷¨¯<≤=≥>≠∨∧×?⍵∊⍴~↑↓⍳○*⊢∙⍺⌈⌊_∇∆∘\'⎕⍎⍕∙⊂⊃∩∪⊥⊤|⍝⍀⌿⋄←→⌹⌶⍫⍒⍋⌽⍉⊖⍟⍱⍲!⍰W⍷R⍨YU⍸⍥⍣⊣ASDF⍢H⍤⌸⌷≡≢⊆⊇CVB¤∥⍪⍙⍠⌺⍞⍬'.replace(/∙/g,'')
,tc={},bqc={} //tab completions and ` completions
for(let i=0;i<bqk.length;i++)bqc[bqk[i]]=bqv[i]
for(let i=0;i<tcs.length;i+=3)tc[tcs[i]+tcs[i+1]]=tcs[i+2]
for(let i=0;i<tcs.length;i+=3){let k=tcs[i+1]+tcs[i];tc[k]=tc[k]||tcs[i+2]}
let lbh='';for(let i=0;i<lbs.length;i++){
  let ks=[]
  for(let j=0;j<tcs.length;j+=3)if(lbs[i][0]===tcs[j+2])ks.push('\n'+tcs[j]+' '+tcs[j+1]+' <tab>')
  for(let j=0;j<bqk.length;j++)if(lbs[i][0]===bqv[j])ks.push('\n` '+bqk[j])
  lbh+='<b title="'+he(lbs[i].slice(1)+(ks.length?'\n'+ks.join(''):''))+'">'+lbs[i][0]+'</b>'
}
let d=document,el=d.createElement('div');el.innerHTML=
`<div class=ngn_lb><span class=ngn_x title=Close>❎</span>${lbh}</div>
 <style>@font-face{font-family:"APL385 Unicode";src:local("APL385 Unicode"),url(//abrudz.github.io/lb/Apl385.woff)format('woff');}</style>
 <style>
  .ngn_lb{position:fixed;top:0;left:0;right:0;background-color:#fff;color:#000;cursor:default;z-index:2147483647;
    font-family:"Apl385 Unicode",monospace;border-bottom:solid #999 1px;padding:2px 2px 0 2px;word-wrap:break-word;}
  .ngn_lb b{cursor:pointer;padding:0 1px;font-weight:normal}
  .ngn_lb b:hover,.ngn_bq .ngn_lb{background-color:#777;color:#fff}
  .ngn_x{float:right;color:#999;cursor:pointer;margin-top:-3px}
  .ngn_x:hover{color:#f00}
  [title~="exponential"]{display:none;}
  [title~="logarithm"]{display:none;}
  [title~="inverse"]{display:none;}
  [title~="pi"]{display:none;}
  [title~="factorial"]{display:none;}
  [title~="roll"]{display:none;}
  [title~="residue"]{display:none;}
  [title~="ceiling"]{display:none;}
  [title~="floor"]{display:none;}
  [title~="decode"]{display:none;}
  [title~="encode"]{display:none;}
  [title~="same"]{display:none;}
  [title~="unique"]{display:none;}
  [title~="less"]{display:none;}
  [title~="greater"]{display:none;}
  [title~="depth"]{display:none;}
  [title~="tally"]{display:none;}
  [title~="greatest"]{display:none;}
  [title~="lowest"]{display:none;}
  [title~="nand"]{display:none;}
  [title~="nor"]{display:none;}
  [title~="mix"]{display:none;}
  [title~="split"]{display:none;}
  [title~="enclose"]{display:none;}
  [title~="pick"]{display:none;}
  [title~="nest"]{display:none;}
  [title~="materialise"]{display:none;}
  [title~="grade"]{display:none;}
  [title~="where"]{display:none;}
  [title~="enlist"]{display:none;}
  [title~="find"]{display:none;}
  [title~="intersection"]{display:none;}
  [title~="without"]{display:none;}
  [title~="catenate"]{display:none;}
  [title~="reverse"]{display:none;}
  [title~="transpose"]{display:none;}
  [title~="each"]{display:none;}
  [title~="swap"]{display:none;}
  [title~="repeat"]{display:none;}
  [title~="product"]{display:none;}
  [title~="over"]{display:none;}
  [title~="at"]{display:none;}
  [title~="rank"]{display:none;}
  [title~="STDIN"]{display:none;}
  [title~="variant"]{display:none;}
  [title~="index"]{display:none;}
  [title~="stencil"]{display:none;}
  [title~="I-beam"]{display:none;}
  [title~="execute"]{display:none;}
  [title~="format"]{display:none;}
  [title~="abort"]{display:none;}
  [title~="recursion"]{display:none;}
  [title~="spawn"]{display:none;}
  [title~="VECTOR"]{display:none;}
  [title~="IDENTIFIER"]{display:none;}
 </style>`
d.body.appendChild(el)
let t,ts=[],lb=el.firstChild,bqm=0 //t:textarea or input, lb:language bar, bqm:backquote mode
let pd=x=>x.preventDefault()
let ev=(x,t,f,c)=>x.addEventListener(t,f,c)
ev(lb,'mousedown',x=>{
  if(x.target.classList.contains('ngn_x')){lb.hidden=1;upd();pd(x);return}
  if(x.target.nodeName==='B'&&t){
    let i=t.selectionStart,j=t.selectionEnd,v=t.value,s=x.target.textContent
    if(i!=null&&j!=null){t.value=v.slice(0,i)+s+v.slice(j);t.selectionStart=t.selectionEnd=i+s.length}
    pd(x);return
  }
})
let fk=x=>{
  let t=x.target
  if(bqm){let i=t.selectionStart,v=t.value,c=bqc[x.key];if(x.which>31){bqm=0;d.body.classList.remove('ngn_bq')}
          if(c){t.value=v.slice(0,i)+c+v.slice(i);t.selectionStart=t.selectionEnd=i+1;pd(x);return!1}}
  if (!x.ctrlKey && !x.shiftKey && !x.altKey && !x.metaKey) {
    if ("`½²^º§ùµ°".indexOf(x.key) > -1) {
      bqm=1;d.body.classList.add('ngn_bq');pd(x); // ` or other trigger symbol pressed, wait for next key
    } else if (x.key == "Tab") {
      let i=t.selectionStart,v=t.value,c=tc[v.slice(i-2,i)]
      if(c){t.value=v.slice(0,i-2)+c+v.slice(i);t.selectionStart=t.selectionEnd=i-1;pd(x)}
    }
  }
}
let ff=x=>{
  let t0=x.target,nn=t0.nodeName.toLowerCase()
  if(nn!=='textarea'&&(nn!=='input'||t0.type!=='text'&&t0.type!=='search'))return
  t=t0;if(!t.ngn){t.ngn=1;ts.push(t);ev(t,'keydown',fk)}
}
let upd=_=>{d.body.style.marginTop=lb.clientHeight+'px'}
upd();ev(window,'resize',upd)
ev(d,'focus',ff,!0);let ae=d.activeElement;ae&&ff({type:'focus',target:ae})
})();
