(* ::Package:: *)
(* ::Title:: *)
(*Html2Markdown*)
(* ::Subchapter:: *)
(*程序包介绍*)
(* ::Text:: *)
(*Mathematica Package*)
(*Created by Mathematica Plugin for IntelliJ IDEA*)
(**)
(* ::Text:: *)
(*Creation Date: 2018-03-12*)
(*Copyright: Mozilla Public License Version 2.0*)
(* ::Program:: *)
(*1.软件产品再发布时包含一份原始许可声明和版权声明。*)
(*2.提供快速的专利授权。*)
(*3.不得使用其原始商标。*)
(*4.如果修改了源代码，包含一份代码修改说明。*)
(* ::Section:: *)
(*函数说明*)
BeginPackage["Html2Markdown`"];
Html2Markdown::usage = "将HTML转化为Markdown格式的方案集合.";
H2MD::usage = "将HTML转化为Markdown格式.\r
	Module->\"Zhihu\", 针对知乎回答的转换方案\r
	Module->\"Zhuanlan\", 针对知乎专栏的转换方案\r
	Module->\"WordPress\", 针对 wp 的转换方案\r
";
$DirectoryH2MD::usage = "打开 Html2Markdown 的缓存目录.";
(* ::Section:: *)
(*程序包正体*)
Begin["`Private`"];
(* ::Subsection::Closed:: *)
(*主体代码*)
$dir=FileNameJoin[{$UserBaseDirectory,"ApplicationData","Html2Markdown"}];
Quiet@CreateDirectory[$dir];
$DirectoryH2MD[]:=SystemOpen@$dir;
Options[H2MD]={Module->"Zhihu",Save->False};
H2MD[input_String,OptionsPattern[]]:=Switch[
	OptionValue[Module],
	"Zhihu",
		ZhihuH2MD[input],
	"Zhuanlan",
		ZhuanlanH2MD[input]
];
(* ::Subsubsection:: *)
(*ZhihuH2MD*)
Options[ZhihuH2MD]={Debug->False};
ZhihuH2MD[input_String,OptionsPattern[]]:=Block[
	{xml,yu,body},
	xml=ImportString[input,{"HTML","XMLObject"}];
	yu=xml/.{
		XMLElement["p",{},{XMLElement["img",{"src"->__,"alt"->tex__,__},{}]}]:>StringJoin["\n$$",tex,"$$\n"],(*tex 行间公式*)
		XMLElement["p",{},{para__}]:>StringJoin["\n",para,"\n"],(*tex 行内公式*)
		XMLElement["img",{___,"data-original"->img__,___},{}]:>StringJoin["![](",img,")"],
		XMLElement["img",{___,"data-actualsrc"->img__,___},{}]:>StringJoin["![](",img,")"],
		XMLElement["noscript",___]:>Nothing,
		XMLElement["li",{},{li__}]:>StringJoin["> ",li,"\n"],
		XMLElement["a",{___,"href"->url_,___},{f__}]:>StringJoin["[",f,"](",url,")"],
		XMLElement["figcaption",{},{}]:>"\n图注:",
		XMLElement["br",___]:>"\n",
		XMLElement["code",___,{__,code_}]:>StringJoin["\n```\n",code,"```\n"]
	};
	body=Part[yu/.{
		XMLElement["hr",{},{}]:>"\n---\n",
		XMLElement["figure",{},{}]:>Nothing,
		XMLElement["ul",{},{ul__}]:>StringJoin["\n",ul,"\n"],
		XMLElement["div",___,{XMLElement["pre",{},{raw_}]}]:>raw,
		XMLElement["blockquote",{},q_]:>StringJoin@Riffle[q,"> ",{1,-1,3}]
	},2,3,1];
	If[OptionValue[Debug],
		Return[body],
		StringJoin[ToString/@body[[3]]]
	]
];
(* ::Subsection::Closed:: *)
(*附加设置*)
End[];
SetAttributes[
	{},
	{Protected,ReadProtected}
];
EndPackage[]