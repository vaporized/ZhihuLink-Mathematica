$ZhihuLinkDirectory::usage = "打开 ZhihuLink 的缓存目录.";
Begin["`Private`"];
$zdir=FileNameJoin[{$UserBaseDirectory,"ApplicationData","ZhihuLink"}];
$sd=FileNameJoin[{$zdir,"stats"}];
$fd=FileNameJoin[{$zdir,"follows"}];
Quiet[CreateDirectory/@{$zdir,$sd,$fd}];
$ZhihuLinkDirectory[]:=SystemOpen@$zdir;
End[] ;
SetAttributes[
	{$ZhihuLinkDirectory},
	{Protected,ReadProtected}
];