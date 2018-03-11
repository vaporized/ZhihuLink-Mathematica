ZhihuLink::usage = "ZhihuLink 是一个获取知乎数据的链接程序.";
$ZhihuCookies::usage = "知乎Cookies, 有效期约一个月.";
$ZhihuLinkDirectory::usage = "打开 ZhihuLink 的缓存目录.";
ZhihuStats::usage = "ZhihuStats[id] 获取用户的数据";
ZhihuFollow::usage = "ZhihuFollow[id] 获取用户的关注者数据.";
ZhihuCookiesReset::usage = "修改你的 Zhihu Cookies.";
Begin["`Private`"];
ZhihuLink$Version="V1.0";
ZhihuLink$LastUpdate="2018-03-10";
$zdir=FileNameJoin[{$UserBaseDirectory,"ApplicationData","ZhihuLink"}];
$sd=FileNameJoin[{$zdir,"stats"}];
$fd=FileNameJoin[{$zdir,"follows"}];
Quiet@If[
	CreateDirectory[$zdir]===$Failed,
	Nothing,
	CreateDirectory/@{$sd,$fd}
];
$ZhihuLinkDirectory[]:=SystemOpen@$zdir;
$ZhihuLinkAutoSave=True;
If[FindFile["zhihu.cookies"] === $Failed,
	$ZhihuCookies = "";
	"未检测到 zhihu.cookies 文件\n
	请使用 ZhihuCookiesReset[] 设置你的cookies.",
	$ZhihuCookies = Import@FindFile["zhihu.cookies"]
];
ZhihuCookiesReset[]:=CreateDialog[{
	TextCell["粘贴你的Cookies(不需要是字符型)"],
	InputField[Dynamic[$ZhihuCookies],String,ImageSize->{400,400/GoldenRatio^2}],
	DefaultButton[DialogReturn[$ZhihuCookies]]
	},
	WindowTitle->"需要Token"
];
$keywordsMin={
	{"name","用户名"},
	{"url_token","ID"},
	{"follower_count","粉丝数"},
	{"voteup_count","获赞数"},
	{"favorited_count","获收藏"},
	{"thanked_count","获感谢"},
	{TimeObject,"时间戳"}
};
$keywordsNormal={
	{"name","用户名"},
	{"url_token","ID"},
	{"follower_count","粉丝数"},
	{"voteup_count","获赞数"},
	{"favorited_count","获收藏"},
	{"thanked_count","获感谢"},
	{"following_question_count","关注问题数"},
	{"following_count","关注人数"},
	{"answer_count","回答数"},
	{"articles_count","文章数"},
	{"question_count","提问数"},
	{"logs_count","公共编辑数"},
	{"favorite_count","收藏夹数"},
	{"following_favlists_count","关注收藏夹数"},
	{"columns_count","专栏数"},
	{"pins_count","想法数"},
	{TimeObject,"时间戳"}
};
ZhihuLink::para="非法参数 `1` !";
Options[ZhihuStats]={Return->Min,Raw->False};
$StatsNeeds="locations,employments,gender,educations,business,voteup_count,thanked_Count,follower_count,cover_url,
	following_topic_count,following_question_count,following_favlists_count,following_columns_count,avatar_hue,
	answer_count,articles_count,pins_count,question_count,columns_count,commercial_question_count,favorite_count,
	favorited_count,logs_count,included_answers_count,included_articles_count,included_text,message_thread_token,
	account_status,is_active,is_bind_phone,is_force_renamed,is_bind_sina,thank_to_count,is_privacy_protected,
	sina_weibo_url,sina_weibo_name,show_sina_weibo,is_blocking,is_blocked,is_following,is_followed,following_count,
	is_org_createpin_white_user,mutual_followees_count,vote_to_count,vote_from_count,thank_from_count,
	thanked_count,description,hosted_live_count,participated_live_count,allow_message,industry_category,
	org_name,org_homepage,badge[?(type=best_answerer)].topics";
ZhihuStats[name_String,OptionsPattern[]]:=Block[
	{needs=$StatsNeeds,now=Now,get,return,exname},
	get=URLExecute[HTTPRequest[<|
		"Scheme"->"https",
		"Domain"->"www.zhihu.com",
		"Headers"->{"Cookie"->$ZhihuCookies},
		"Path"->{"api/v4/members",name},
		"Query"->{"include"->needs}
	|>],Authentication->None];
	If[
		Head@get===String,
		Message[ZhihuLink::para,name];
		Return@Missing["NotAvailable"]
	];
	exname=StringJoin[name,"+",ToString@IntegerPart[1000AbsoluteTime@now],".json"];
	Export[FileNameJoin[{$sd,exname}],get,"json"];
	If[Raw,Return@get];
	Switch[OptionValue[Return],
		Min,
			return=Join[$keywordsMin[[All;;-2,1]],{now}]/.get;
			Association@Thread[Last@@@$keywordsMin->return],
		Normal,
			return=Join[$keywordsNormal[[All;;-2,1]],{now}]/.get;
			Association@Thread[Last@@@$keywordsNormal->return],
		_,
			Message[ZhihuLink::para,OptionValue[Return]];
			Return@Missing["NotAvailable"]
	]
];
ZhihuFolloweesGet[name_String,offset_Integer]:=Block[
	{get,needs,now=Now},
	needs="data[*].follower_count,voteup_count,favorited_count,thanked_count";
	get="data"/.URLExecute[HTTPRequest[<|
		"Scheme"->"https",
		"Domain"->"www.zhihu.com",
		"Headers"->{"Cookie"->$ZhihuCookies},
		"Path"->{"api/v4/members",name,"followees"},
		"Query"->{"include"->needs,"offset"->offset,"limit"->offset+20}
	|>],Authentication->None];
	exname=StringJoin[ToString@IntegerPart[1000AbsoluteTime@now],".json"];
	Export[FileNameJoin[{$fd,exname}],get,"json"];
	ArrayPad[$keywordsMin[[1;;6,1]]/.get,{{0},{0,1}},now]
];
Options[ZhihuFollow]={Format->Dataset};
ZhihuFollow[name_String,OptionsPattern[]]:=Block[
	{count,raw,data},
	count=ZhihuStats[name,Return->Normal]["关注人数"];
	Echo[count,"你关注的用户数: "];
	raw=Flatten[ZhihuFolloweesGet[name,20#]&/@Range[0,Quotient[count,20]],1];
	Switch[OptionValue[Format],
		TableForm,
			TableForm[raw,TableHeadings\[Rule]{None,Last@@@$keywordsMin}],
		Dataset,
			Association[Rule@@@Transpose@{$keywordsMin[[All,2]],#}]&/@raw//Dataset,
		Raw,
			raw,
		_,
		Message[ZhihuLink::para,OptionValue[Format]];
		Return@Missing["NotAvailable"]
	]
];
End[] ;
SetAttributes[
	{ },
	{Protected,ReadProtected}
];