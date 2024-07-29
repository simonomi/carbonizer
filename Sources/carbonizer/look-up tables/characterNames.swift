let characterNames: [Int32: String] = [
	1:   "Hunter",
//	2:   "Fake Dr. Diggins", // only ever despawned?? (in e0004:60)
//	3:   "Fake Dr. Diggins",
//	4:   "Fake Dr. Diggins",
	5:   "BB Girl 1",
	6:   "BB Girl 2",
	7:   "Mole 1",
	8:   "T-Rex Hunter",
	31:  "Beth", // 12a
	32:  "Wendy",
//	33:  "", // 37e - guys in suits
//	34:  "", // 12c - another beth variation
	35:  "Dr. Diggins 1",
	36:  "Rosie",
	37:  "Mr. Richmond 1",
	38:  "Police Officer 1",
	39:  "Police Officer 2",
	40:  "Bullwort",
	41:  "KL-33N",
//	42:  "", // 37c - guys in suits
//	43:  "", // 37 - guys in suits
//	44:  "", // 37 - guys in suits
//	45:  "", // 37 - guys in suits
//	46:  "", // 28 - uhh guild shopkeep guy and others
//	47:  "", // 28 - uhh guild shopkeep guy and others
//	48:  "", // 28 - uhh guild shopkeep guy and others
//	49:  "", // 28 - uhh guild shopkeep guy and others
//	50:  "", // 28 - uhh guild shopkeep guy and others
//	51:  "", // 28 - uhh guild shopkeep guy and others
//	52:  "" // o09haniwa1 // idolcomps??
//	53:  "" // o09haniwa2
//	54:  "" // o09haniwa3
//	55:  "" // o09haniwa4
	56:  "Boat",
	57:  "BB Boy 1",
	58:  "BB Girl 3",
	59:  "Rex",
	60:  "Snivels",
	61:  "Vivian",
	62:  "BB Boss",
//	63:  "",
//	64:  "",
	65:  "Mask Lady",
//	66:  "",
//	66:  "",
//	68:  "",
	69:  "McJunker", // cha07 head07
	70:  "Medal-Dealer Joe", // cha24 head24
//	71:  "", // cha44c head44c
//	72:  "", // cha44d head44d
//	73:  "", // cha44e head44e
//	74:  "", // cha52d head48a
//	75:  "", // cha37d head37d
	76:  "Denture Shark Red?", // cha13b []
	77:  "Woolbeard", // [cha25, cha25, cha25] [head25a, head25b, head25c]
	78:  "Nick Nack", // cha26 head26
	79:  "Denture Shark 1", // cha13a []
	80:  "Human Duna", // cha09 head09
	81:  "Duna", // cha08 head08
	82:  "Raptin", // cha19 head19
	83:  "Triconodonta", // cha11a []
	84:  "Triconodonta Rosie", // cha11b []
	85:  "Saurhead", // cha15 head15
//	86:  "", // cha38c head38c
//	87:  "", // cha40d head40d
	88:  "Dinaurian 1", // cha33 head33
	89:  "Dinaurian 2", // cha33 head33
	90:  "Dinaurian 3", // cha33 head33
	91:  "Dinaurian 4", // cha33 head33
	92:  "Dinaurian 5", // cha33 head33
	93:  "Dinaurian 6", // cha33 head33
	94:  "Dinaurian 7", // cha33 head33
	95:  "Dinaurian 8", // cha33 head33
	96:  "Dinaurian 9", // cha33 head33
	97:  "Dynal", // [cha29, cha20] [head29, head20]
//	98:  "", // cha37a head37a //オソロシの森通行禁止係員→一般職員
//	99:  "", // saku [] //オソロシの柵
//	100: "", // saku [] //オソロシの柵
//	101: "", // saku [] //オソロシの柵
//	102: "", // saku [] //オソロシの柵
//	103: "", // o02mono []
//	104: "", // o02mono []
	105: "Digadig 1", // cha30 head30 //ディグディグ人の男
	106: "Digadig 2", // cha30 head30 //ディグディグ人の男
	107: "Digadig 3", // cha30 head30 //ディグディグ人の男
	108: "Digadig Chieftain", // cha21 head21 //ディグディグ人の男
//	109: "", // cha42d head42d
	110: "Oonga Oonga", // cha27 []
	111: "Mr. Richmond 2", // cha20 head20
	112: "Dr. Diggins 2", // cha03b head03b
//	113: "", // t02atm_3 []
	114: "Nevada", // cha14 head14
//	115: "", // cha40d head40d
//	116: "", // cha37b head37b
//	117: "", // cha40e head40e
//	118: "", // cha42b head42b
//	119: "", // cha12d head12d
	120: "Trent", // cha38d head38d
	121: "Zoe", // cha45a head45a
//	122: "", // cha38b head38b
//	123: "", // cha38e head38e
//	124: "", // cha39b head39b
	125: "Edward", // cha44c head44c
//	126: "", // [cha38d, cha36b] [head38d, head36b]
//	127: "", // [cha45b, cha10a] [head45b, head10a]
	128: "Jenna", // cha39a head39a
	129: "Tracy", // cha10c head10c
	130: "Peggy", // cha45e2 head45e
	131: "Security Guard", // cha36c head36c // pre-tutorial
	132: "Cleaning Room Staff", // cha37a head37a
	133: "Busy Fossil Center Staff", // cha37a head37a
	134: "Warehouse Guard Staff", // cha37a head37a
	135: "Diana", // cha45b head45b
//	136: "", // cha36c head36c
//	137: "", // cha36c head36c
//	138: "", // cha36c head36c
	139: "Holt 1", // cha31 head31
//	140: "", // cha28e head28e
//	141: "", // cha28c head28c
	142: "Samurai", // cha16 head16
//	143: "", // cha36a head36a
//	144: "", // cha36a head36a
//	145: "", // cha44e head44e
//	146: "", // cha38a head38a
//	147: "", // cha44a head44a
//	148: "", // cha45d head45d
//	149: "", // cha40b head40b
//	150: "", // cha37d head37d
//	151: "", // cha10e head10e
//	152: "", // cha28b head28b
//	153: "", // cha44a head44a
//	154: "", // cha45d head45d
//	155: "", // cha50a head45c
//	156: "", // cha43c head43c
//	157: "", // cha38a head38a
//	158: "", // cha42c head42c
//	159: "", // cha32 head32
//	160: "", // cha36a head36a
	161: "Hunter/Rosie Rock", // cha0102_rock []
	162: "Hunter/Duna Rock", // cha0108_rock []
	163: "Dr. Diggins Rock", // cha03_rock []
	164: "Duna Rock", // cha08_rock []
//	165: "", // cha37a head37a
//	166: "", // [] []
//	167: "", // cha37b head37b
//	168: "", // cha28b head28b
//	169: "", // cha28b head28b
//	170: "", // cha45b mask13
//	171: "", // cha39c head39c
//	172: "", // cha42d head42d
//	173: "", // cha44e head44e
//	174: "", // cha37a head37a
//	179: "", // cha38c head38c
//	180: "", // takara []
//	181: "", // takara02 []
	182: "Rosie Paralysis", // cha02_paralysis head02
	183: "Mr. Richmond Paralysis", // cha20_paralysis head20
	184: "Dr. Diggins Paralysis", // cha03_paralysis head03b
	185: "Duna Paralysis", // cha08_paralysis head08
//	186: "", // r22mono1a []
//	187: "", // r22mono1b []
	188: "Fossil Center Staff", // cha37a head37a // pre-tutorial
//	189: "", // [] []
//	190: "", // [] []
//	191: "", // cha36b head36b
//	192: "", // cha199 []
//	193: "", // cha199 []
//	194: "", // [] []
//	195: "", // [] []
//	196: "", // [] []
//	197: "", // [] []
//	198: "", // [] []
	199: "Camera Focus", // [] []
	200: "Docked Ship", // t01ship []
//	201: "", // o01iwa2 []
//	202: "", // o01iwa1 []
//	203: "", // o02kabu2 []
//	204: "", // o02kabu1 []
//	205: "", // o02hone2 []
//	206: "", // o02hone1 []
//	207: "", // o02mono []
//	208: "", // otosiana1 []
//	209: "", // otosiana2 []
//	210: "", // hasigo []
//	211: "", // o03iwa2 []
//	212: "", // o03iwa1 []
//	213: "", // o03iwa4 []
//	214: "", // o03iwa3 []
//	215: "", // o04sabo2 []
//	216: "", // o04sabo1 []
//	217: "", // o05iwa2 []
//	218: "", // o05iwa1 []
//	219: "", // sango1 []
//	220: "", // sango2 []
//	221: "", // sango3 []
//	222: "", // ana []
//	223: "", // o05taru2 []
//	224: "", // o05taru1 []
//	225: "", // takara []
//	226: "", // o06iwa2 []
//	227: "", // o06iwa1 []
//	228: "", // o07ice2 []
//	229: "", // o07ice1 []
//	230: "", // o08iwa2 []
//	231: "", // o08iwa1 []
//	232: "", // o08iwa3 []
//	233: "", // [o08iwa4_1, //座標0.0に設置のため、当たり判定を設定不可能。別に透明objを設置して当たり判定つける] []
//	234: "", // [o08iwa4_2, //座標0.0に設置のため、当たり判定を設定不可能。別に透明objを設置して当たり判定つける] []
//	235: "", // [o08iwa4_3, //座標0.0に設置のため、当たり判定を設定不可能。別に透明objを設置して当たり判定つける] []
//	236: "", // sen []
//	237: "", // o09iwa1 []
//	238: "", // o09iwa2 []
//	239: "", // o10iwa2 []
//	240: "", // o10iwa1 []
//	241: "", // o10tablet []
//	248: "", // t01cannon []
//	249: "", // r22mono1 []
//	250: "", // r22mono2 []
//	251: "", // r22mono3 []
//	252: "", // r10fan []
//	253: "", // t02fan []
//	254: "", // r50tree []
//	255: "", // o03ita []
//	256: "", // o04oasisu []
//	257: "", // o09warp1 []
//	258: "", // o09warp2 []
//	259: "", // o10sleep1 []
//	260: "", // o10sleep2 []
//	261: "", // saku []
//	262: "", // o10harmage []
//	263: "", // o03trk_br []
//	264: "", // o03trk_re []
//	265: "", // o03pnl_ok []
//	266: "", // o03pnl_no []
//	267: "", // o03mg_iwa []
//	268: "", // ana []
//	269: "", // ana []
//	270: "", // o05iwa2 []
//	271: "", // o05iwa2 []
//	272: "", // o05iwa2 []
//	273: "", // ana []
//	274: "", // o10tablet []
//	275: "", // o10tablet []
//	276: "", // o10tablet []
//	277: "", // o10tablet []
//	278: "", // takara []
//	279: "", // takara []
//	280: "", // takara []
//	281: "", // [] []
//	282: "", // [] []
//	283: "", // [] []
//	284: "", // [] []
//	285: "", // [] []
//	286: "", // cha36b head36b
//	287: "", // o08iwa2 []
//	288: "", // otosiana1 []
//	289: "", // o04oasisu []
//	290: "", // o04oasisu []
//	291: "", // o04oasisu []
//	292: "", // r01door []
//	293: "", // r01door []
//	294: "", // cha44c head44c
//	295: "", // cha45c head45c
//	296: "", // cha40e head40e
//	297: "", // r01door []
//	298: "", // r03door []
//	299: "", // r20door_1 []
//	300: "", // r20door_1 []
//	301: "", // r24door []
//	302: "", // r24door []
//	303: "", // r24door []
//	304: "", // r25door []
//	305: "", // r25door []
//	306: "", // r25door []
//	307: "", // r20door_2 []
//	308: "", // r20door_2 []
//	309: "", // r30door []
//	310: "", // r31door []
//	311: "", // r40door []
//	312: "", // r40door []
//	313: "", // r40door []
//	314: "", // r41door1 []
//	315: "", // r41door1 []
//	316: "", // r41door2 []
//	317: "", // r44door []
//	318: "", // r50door []
//	319: "", // r50door []
//	320: "", // r51door []
//	321: "", // r52door []
//	322: "", // r53door []
//	323: "", // o02door []
//	324: "", // o05door1 []
//	325: "", // o05door2 []
//	326: "", // o08door_1 []
//	327: "", // o08door_2 []
//	328: "", // o08door_3 []
//	329: "", // o09door_1 []
//	330: "", // o09door_2 []
//	331: "", // o09door_3 []
//	332: "", // o10door_1 []
//	333: "", // o10door_2 []
//	334: "", // o10door_3 []
//	335: "", // cha40a head40a
//	336: "", // cha34 head34
//	337: "", // [] []
//	338: "", // cha34 head34
//	339: "", // cha34 head34
//	340: "", // cha35 head35
//	341: "", // cha34 head34
	342: "Sea Ship", // sea01ship []
//	343: "", // [] []
//	344: "", // [] []
//	345: "", // [] []
	346: "Denture Shark 2", // cha13a []
	347: "Denture Shark 3", // cha13a []
	348: "Denture Shark 4", // cha13a []
	349: "Denture Shark 5", // cha13a []
//	350: "", // o03trk_re []
//	351: "", // [] []
//	352: "", // otosiana1 []
//	353: "", // [] []
//	354: "", // cha199 []
//	355: "", // o03iwa4 []
//	356: "", // o08iwa2 []
//	357: "", // o03iwa2 []
	358: "Hunter Ice", // cha01_ice []
	359: "Rosie Ice", // cha02_ice []
//	360: "", // r24door []
//	361: "", // r24door []
//	362: "", // r25door []
//	363: "", // r50tree []
//	364: "", // r50tree []
//	365: "", // r50tree []
//	366: "", // otosiana1 []
//	367: "", // otosiana1 []
//	368: "", // [saku, //オソロシの柵] []
//	369: "", // [saku, //オソロシの柵] []
//	370: "", // o02door1 []
//	371: "", // o08iwa3_2 []
//	372: "", // cha44a head44a
//	373: "", // cha44b head44b
//	374: "", // cha44c head44c
//	375: "", // cha44d head44d
//	376: "", // cha44e head44e
//	377: "", // cha45a head45a
//	378: "", // cha45b head45b
//	379: "", // cha45c head45c
//	380: "", // cha45d head45d
//	381: "", // cha45e head45e
//	382: "", // [] []
//	383: "", // [] []
//	384: "", // [] []
//	385: "", // [] []
//	386: "", // o02hone1 []
//	387: "", // o02hone1 []
//	388: "", // o11haruma []
//	389: "", // r50tree []
//	390: "", // r50tree []
//	391: "", // r50tree []
//	392: "", // r50tree []
//	393: "", // r50tree []
//	394: "", // r50tree []
//	395: "", // o01iwa2 []
//	396: "", // o02kabu2 []
//	397: "", // o02hone2 []
//	398: "", // o04sabo2 []
//	399: "", // o05iwa2 []
//	400: "", // o05taru2 []
//	401: "", // o06iwa2 []
//	402: "", // o07ice2 []
//	403: "", // o09iwa1 []
//	404: "", // o10iwa2 []
	405: "Sue", // cha12c head12c
//	406: "", // r50tree []
//	407: "", // r50tree []
//	408: "", // [] []
//	409: "", // [] []
//	410: "", // [] []
//	411: "", // [] []
//	412: "", // [] []
//	413: "", // [] []
//	414: "", // [] []
//	415: "", // [] []
//	416: "", // [] []
//	417: "", // [] []
//	418: "", // [] []
//	419: "", // [] []
//	420: "", // [] []
//	421: "", // [] []
//	422: "", // [] []
//	423: "", // [] []
//	424: "", // [] []
//	425: "", // [] []
//	426: "", // [] []
//	427: "", // [] []
//	428: "", // [] []
//	429: "", // [] []
//	430: "", // [] []
//	431: "", // [] []
//	432: "", // [] []
//	433: "", // [] []
//	434: "", // [] []
//	435: "", // [] []
//	436: "", // [] []
//	437: "", // [] []
//	438: "", // [] []
//	439: "", // [] []
//	440: "", // [] []
//	441: "", // [] []
//	442: "", // [] []
//	443: "", // [] []
//	444: "", // [] []
//	445: "", // [] []
//	446: "", // [] []
//	447: "", // [] []
//	448: "", // [] []
//	449: "", // [] []
//	450: "", // [] []
//	451: "", // [] []
//	452: "", // [] []
//	453: "", // [] []
//	454: "", // [] []
//	455: "", // [] []
//	456: "", // [] []
//	457: "", // [] []
//	458: "", // [] []
//	459: "", // [] []
//	460: "", // [] []
//	461: "", // t02atm_3 []
//	462: "", // t02atm_3 []
//	463: "", // t02atm_3 []
//	464: "", // t02atm_3 []
//	465: "", // t02atm_2 []
//	466: "", // t02atm_1 []
//	467: "", // t02atm_1 []
//	468: "", // t02atm_2 []
//	469: "", // t02atm_1 []
//	470: "", // t02atm_1 []
//	471: "", // t02atm_1 []
//	472: "", // t02atm_1 []
//	473: "", // t02atm_1 []
//	474: "", // t02atm_1 []
//	475: "", // t02atm_1 []
//	476: "", // t02atm_1 []
//	477: "", // t02atm_2 []
//	478: "", // t02atm_2 []
//	479: "", // t02atm_2 []
//	480: "", // [] []
//	481: "", // [] []
//	482: "", // [] []
//	483: "", // [] []
//	484: "", // [] []
	485: "BB Boy 2", // cha34 head34
	486: "BB Boy 3", // cha34 head34
	487: "BB Girl 4", // cha35 head35
	488: "BB Boy 4", // cha34 head34
	489: "BB Boy 5", // cha34 head34
	490: "BB Boy 6", // cha34 head34
	491: "BB Girl 5", // cha35 head35
	492: "BB Boy 7", // cha34 head34
//	493: "", // [] []
//	494: "", // [] []
//	495: "", // [] []
//	496: "", // [] []
//	497: "", // [] []
//	498: "", // [] []
//	499: "", // parasoru []
//	500: "", // taku []
//	501: "", // takara02 []
//	502: "", // takara02 []
//	503: "", // takara02 []
//	504: "", // takara02 []
//	505: "", // o03trk_re []
//	506: "", // o03trk_br []
//	507: "", // o03trk_br []
//	508: "", // o03trk_re []
//	509: "", // [] []
//	510: "", // [] []
	511: "Mr. Richmond 3", // cha20 head20
//	512: "", // r25door []
//	513: "", // kasekimusi1 []
//	514: "", // kasekimusi2 []
//	515: "", // [] []
//	516: "", // [] []
//	517: "", // [] []
//	518: "", // [] []
//	519: "", // [] []
//	520: "", // [] []
//	521: "", // [] []
//	522: "", // t02atm_2 []
//	523: "", // t02atm_2 []
//	524: "", // t02atm_1 []
//	525: "", // t02atm_1 []
//	526: "", // t02atm_1 []
//	527: "", // [] []
//	528: "", // cha44a mask10
//	529: "", // cha44b mask10
//	530: "", // cha44c mask10
//	531: "", // cha44d mask10
//	532: "", // cha45a mask13
//	533: "", // cha45b mask13
//	534: "", // cha45c mask13
//	535: "", // cha45d mask13
//	536: "", // r40door []
//	537: "", // [] []
//	538: "", // [] []
//	539: "", // [] []
//	540: "", // [] []
//	541: "", // [cha44d, cha44b] [head44d, head44b]
//	542: "", // [cha44e, cha44c] [head44e, head44c]
//	543: "", // [cha45a, cha45e] [head45a, head45e]
//	544: "", // [cha45c, cha45d] [head45c, head45d]
//	545: "", // cha47a head47a
//	546: "", // o10sleep3 []
//	547: "", // o02door1 []
//	548: "", // [] []
//	549: "", // [] []
//	550: "", // [] []
//	551: "", // [] []
//	552: "", // [] []
//	553: "", // cha37a head37a
//	554: "", // t02atm_2 []
//	555: "", // t02atm_2 []
//	556: "", // t02atm_2 []
//	557: "", // t02atm_2 []
//	558: "", // t02atm_2 []
//	559: "", // t02atm_2 []
//	560: "", // t02atm_2 []
//	561: "", // t02atm_2 []
//	562: "", // t02atm_2 []
//	563: "", // t02atm_2 []
//	564: "", // t02atm_2 []
//	565: "", // t02atm_2 []
//	566: "", // t02atm_2 []
//	567: "", // t02atm_2 []
//	568: "", // t02atm_2 []
//	569: "", // t02atm_2 []
//	570: "", // t02atm_2 []
//	571: "", // t02atm_2 []
//	572: "", // t02atm_2 []
//	573: "", // t02atm_2 []
//	574: "", // t02atm_2 []
//	575: "", // t02atm_2 []
//	576: "", // t02atm_2 []
//	577: "", // t02atm_2 []
//	578: "", // t02atm_2 []
//	579: "", // t02atm_2 []
//	580: "", // t02atm_2 []
//	581: "", // t02atm_2 []
//	582: "", // t02atm_2 []
//	583: "", // t02atm_2 []
//	584: "", // t02atm_2 []
//	585: "", // t02atm_2 []
//	586: "", // t02atm_2 []
//	587: "", // t02atm_2 []
//	588: "", // t02atm_2 []
//	589: "", // otosiana2 []
//	590: "", // hasigo []
	591: "Mole 2", // cha18 head18
	592: "Mole 3", // cha18 head18
//	593: "", // o03mg_iwa []
//	594: "", // o03mg_iwa []
//	595: "", // o03mg_iwa []
//	596: "", // o03mg_iwa []
//	597: "", // o03mg_iwa []
//	598: "", // takara []
//	599: "", // o10tablet []
//	600: "", // o10tablet []
//	601: "", // takara02 []
//	602: "", // cha10e head10e
//	603: "", // [] []
//	604: "", // cha34 head34
//	605: "", // cha34 head34
//	606: "", // cha35 head35
//	607: "", // cha35 head35
//	608: "", // cha34 head34
//	609: "", // cha35 head35
//	610: "", // cha34 head34
//	611: "", // cha34 head34
//	612: "", // cha35 head35
//	613: "", // [] []
//	614: "", // o05door3 []
//	615: "", // takara []
//	616: "", // takara []
//	617: "", // takara02 []
//	618: "", // takara02 []
//	619: "", // o10tablet []
//	620: "", // o10tablet []
//	621: "", // o10tablet []
//	622: "", // o10tablet []
//	623: "", // cha17b []
//	624: "", // o10tablet []
//	625: "", // o10tablet []
//	626: "", // o10tablet []
//	627: "", // cha50a head45a
//	628: "", // cha50a head45c
//	629: "", // cha50a head47a
//	630: "", // cha50b head45b
//	631: "", // cha50b head45d
//	632: "", // cha50b head47b
//	633: "", // cha50c head45c
//	634: "", // cha50c head45e
//	635: "", // cha50c head47c
//	636: "", // cha50d head45d
//	637: "", // cha50d head45a
//	638: "", // cha50d head47a
//	639: "", // cha51a head45e
//	640: "", // cha51a head45b
//	641: "", // cha51a head47c
//	642: "", // cha51b head45d
//	643: "", // cha51b head45a
//	644: "", // cha51b head47a
//	645: "", // cha51c head45c
//	646: "", // cha51c head45e
//	647: "", // cha51c head47b
//	648: "", // cha51d head45b
//	649: "", // cha51d head45e
//	650: "", // cha51d head47c
//	651: "", // cha52a head48a
//	652: "", // cha52a head48b
//	653: "", // cha52a head48c
//	654: "", // cha52a head44b
//	655: "", // cha52b head48a
//	656: "", // cha52b head48b
//	657: "", // cha52b head48c
//	658: "", // cha52b head44b
//	659: "", // cha52c head48a
//	660: "", // cha52c head48c
//	661: "", // cha52c head44e
//	662: "", // cha52d head48a
//	663: "", // cha52d head48c
//	664: "", // cha52d head44e
//	665: "", // cha44b head48b
//	666: "", // cha44c head48a
//	667: "", // cha44c head48b
//	668: "", // cha44d head48b
//	669: "", // cha44e head48b
//	670: "", // cha44e head48c
//	671: "", // cha52a mask10
//	672: "", // cha52b mask10
//	673: "", // cha52c mask10
//	674: "", // cha52d mask10
//	675: "", // cha50a mask13
//	676: "", // cha50b mask13
//	677: "", // cha51c mask13
//	678: "", // cha51d mask13
//	679: "", // cha46a head46a
//	680: "", // cha46b head46b
//	681: "", // cha46c head46c
//	682: "", // cha46a head48a
//	683: "", // cha46c head44e
//	684: "", // cha47a head47a
//	685: "", // cha47b head47b
//	686: "", // cha47c head47c
//	687: "", // cha47b head45d
//	688: "", // cha47c head45e
//	689: "", // cha10a head10a
//	690: "", // cha44d head44d
//	691: "", // cha45e head45e
//	692: "", // cha52a head48c
//	693: "", // cha52b head44b
//	694: "", // cha44a head44a
//	695: "", // cha45a head45a
//	696: "", // cha44d head48b
//	697: "", // cha44c head44c
//	698: "", // cha45d head45d
//	699: "", // cha51c head47b
//	700: "", // cha46b head46b
//	701: "", // cha45c head45c
//	702: "", // cha52a head48c
//	703: "", // cha44b head44b
//	704: "", // cha52b head48b
//	705: "", // cha52b head48a
//	706: "", // cha44a head44a
//	707: "", // cha45c head45c
//	708: "", // cha44d head44d
//	709: "", // cha52d head44e
//	710: "", // cha45d head45d
//	711: "", // cha44b head44b
//	712: "", // cha46b head46b
//	713: "", // cha51c head45e
//	714: "", // cha52b mask10
//	715: "", // cha45e head45e
//	716: "", // cha52b head48b
//	717: "", // cha44e head48b
//	718: "", // cha44c head48a
//	719: "", // cha45a head45a
//	720: "", // cha44b head48b
//	721: "", // cha52c head44e
//	722: "", // cha45d head45d
//	723: "", // cha44c head48b
//	724: "", // cha44c head44c
//	725: "", // cha45b head45b
//	726: "", // cha44e head44e
//	727: "", // cha44d head48b
//	728: "", // cha52b head48b
//	729: "", // cha46a head46a
//	730: "", // cha52d head48c
//	731: "", // cha51c head45e
//	732: "", // cha44a head44a
//	733: "", // cha52b head48c
//	734: "", // cha45d head45d
//	735: "", // cha44c head48a
//	736: "", // cha44d head44d
//	737: "", // cha47c head45e
//	738: "", // cha46a head46a
//	739: "", // cha44e head44e
//	740: "", // cha52b head48b
//	741: "", // cha52a head48a
//	742: "", // cha46a head48a
//	743: "", // cha47c head47c
//	744: "", // o09time2 []
//	745: "", // [] []
//	746: "", // [] []
//	747: "", // [] []
//	748: "", // [] []
//	749: "", // [] []
//	750: "", // [] []
//	751: "", // cha44e head48c
//	752: "", // cha44c head44c
//	753: "", // cha52c head48c
//	754: "", // cha44e head44e
//	755: "", // cha52a head44b
//	756: "", // cha50d head45a
//	757: "", // cha44d head44d
//	758: "", // cha44b head44b
//	759: "", // cha51a head47c
//	760: "", // cha44c head44c
//	761: "", // cha52a head48a
//	762: "", // cha47b head45d
//	763: "", // cha47b head47b
//	764: "", // cha50d head47a
//	765: "", // cha44e head48b
//	766: "", // cha50d head45d
//	767: "", // cha52d head44e
//	768: "", // cha45a head45a
//	769: "", // cha45d mask13
//	770: "", // cha51b head45a
//	771: "", // cha52a head44b
//	772: "", // cha44c head48b
//	773: "", // cha52d head44e
//	774: "", // cha45b head45b
//	775: "", // cha52a head48b
//	776: "", // cha44b head44b
//	777: "", // cha45d head45d
//	778: "", // cha44c head44c
//	779: "", // cha44a head44a
//	780: "", // cha50b head45b
//	781: "", // cha50c head45c
//	782: "", // cha52c head48a
//	783: "", // cha51a head47c
//	784: "", // cha52b head48c
//	785: "", // cha52c head44e
//	786: "", // cha51c head45e
//	787: "", // cha51c head45e
//	788: "", // cha46b head46b
//	789: "", // cha52a head44b
//	790: "", // cha52b head48b
//	791: "", // cha52c head48a
//	792: "", // cha45e head45e
//	793: "", // cha52b head48c
//	794: "", // cha52d head48a
//	795: "", // cha44b head44b
//	796: "", // cha46b head46b
//	797: "", // cha51d head45b
//	798: "", // cha52a head48b
//	799: "", // cha44b head44b
//	800: "", // cha45e head45e
//	801: "", // cha44e head48b
//	802: "", // cha44e head44e
//	803: "", // cha44b head44b
//	804: "", // cha45a head45a
//	805: "", // cha45c head45c
//	806: "", // cha52a head44b
//	807: "", // cha51a head45b
//	808: "", // cha44e head48b
//	809: "", // cha44c head48a
//	810: "", // cha51b head45d
//	811: "", // cha51c head45c
//	812: "", // cha44e head48c
//	813: "", // cha46b head46b
//	814: "", // cha52b head48a
//	815: "", // cha44e head48c
//	816: "", // cha45a head45a
//	817: "", // cha50b mask13
//	818: "", // cha44d head44d
//	819: "", // cha52b head48b
//	820: "", // cha51d head47c
//	821: "", // cha44c head48a
//	822: "", // cha51b head45a
//	823: "", // cha44c head44c
//	824: "", // cha52c head44e
//	825: "", // cha45c head45c
//	826: "", // cha44c head48b
//	827: "", // cha44e head48c
//	828: "", // cha45b head45b
//	829: "", // cha52d head48c
//	830: "", // cha44a head44a
//	831: "", // cha52c head48a
//	832: "", // cha46a head46a
//	833: "", // cha52d head48c
//	834: "", // cha51c head45e
//	835: "", // cha45c head45c
//	836: "", // cha51a head45b
//	837: "", // cha44d head44d
//	838: "", // cha45a head45a
//	839: "", // cha44e head48b
//	840: "", // cha45e head45e
//	841: "", // cha45b mask13
//	842: "", // cha44d mask10
//	843: "", // cha45d mask13
//	844: "", // cha44b mask10
//	845: "", // cha44a mask10
//	846: "", // cha45c mask13
//	847: "", // cha45c mask13
//	848: "", // cha45d mask13
//	849: "", // cha44d mask10
//	850: "", // cha45d mask13
//	851: "", // cha44b mask10
//	852: "", // cha45a mask13
//	853: "", // cha44a mask10
//	854: "", // cha45a mask13
//	855: "", // cha45d mask13
//	856: "", // cha44b mask10
//	857: "", // cha44c mask10
//	858: "", // cha45b mask13
//	859: "", // cha45c mask13
//	860: "", // cha45d mask13
//	861: "", // cha45b mask13
//	862: "", // cha44a mask10
//	863: "", // cha44b mask10
//	864: "", // cha45a mask13
//	865: "", // cha44a mask10
//	866: "", // cha45a mask13
//	867: "", // cha45b mask13
//	868: "", // cha44b mask10
//	869: "", // cha44c mask10
//	870: "", // cha45c mask13
//	871: "", // cha45d mask13
//	872: "", // cha44d mask10
//	873: "", // cha44c mask10
//	874: "", // cha44b mask10
//	875: "", // cha45c mask13
//	876: "", // cha44a mask10
//	877: "", // cha51b head47a
//	878: "", // cha52d head44e
//	879: "", // cha51c head45c
//	880: "", // cha51c head45e
//	881: "", // cha44a head44a
//	882: "", // cha51b head45a
//	883: "", // cha44c head44c
//	884: "", // cha50a head45a
//	885: "", // cha51a head47c
//	886: "", // cha52b head48c
//	887: "", // cha52c head44e
//	888: "", // cha51c head45e
//	889: "", // cha47b head47b
//	890: "", // cha52b head44b
//	891: "", // cha52a head44b
//	892: "", // cha44b head44b
//	893: "", // cha52c head48a
//	894: "", // cha45e head45e
//	895: "", // cha51c head45c
//	896: "", // cha52d head48a
//	897: "", // cha44b head44b
//	898: "", // cha44b head44b
//	899: "", // cha51d head45b
//	900: "", // cha52a head48b
//	901: "", // cha44e head44e
//	902: "", // cha50a head45a
//	903: "", // cha52a head48a
//	904: "", // cha50c head47c
//	905: "", // cha52c head48c
//	906: "", // cha47c head45e
//	907: "", // cha52b head48a
//	908: "", // cha46b head46b
//	909: "", // cha52b head48b
//	910: "", // cha52a head44b
//	911: "", // cha44b head44b
//	912: "", // cha47a head47a
//	913: "", // cha45b head45b
//	914: "", // cha44a head44a
//	915: "", // cha52c head48a
//	916: "", // cha46a head46a
//	917: "", // cha44e head48b
//	918: "", // cha45e head45e
//	919: "", // cha45a head45a
//	920: "", // cha44c head48b
//	921: "", // cha44a head44a
//	922: "", // cha51b head47a
//	923: "", // cha52d head44e
//	924: "", // cha52d head48a
//	925: "", // cha44e head44e
//	926: "", // cha47a head47a
//	927: "", // cha44c mask10
//	928: "", // cha47c head47c
//	929: "", // cha45c mask13
//	930: "", // cha44a mask10
//	931: "", // cha44a head44a
//	932: "", // cha52b head48a
//	933: "", // cha52b head48b
//	934: "", // cha50a head45a
//	935: "", // cha50b head45d
//	936: "", // cha52d head48c
//	937: "", // cha46a head48a
//	938: "", // cha46c head44e
//	939: "", // cha46a head46a
//	940: "", // cha47c head47c
//	941: "", // cha46c head46c
//	942: "", // cha47b head47b
//	943: "", // [] []
	944: "Holt 2", // cha31 head31
	945: "Staff Member", // cha37a head37a
//	946: "", // cha50d head47a
//	947: "", // cha50c head47c
//	948: "", // o01iwa2 []
//	949: "", // o01iwa1 []
//	950: "", // cha37a head37a
//	951: "", // cha28d head28b
//	952: "", // ana02 []
//	953: "", // dai []
//	954: "", // cha199 []
//	955: "", // cha199 []
//	956: "", // cha199 []
//	957: "", // cha199 []
//	958: "", // [] []
//	959: "", // [] []
//	960: "", // o08iwa1 []
//	961: "", // o08iwa1 []
//	962: "", // o08iwa1 []
//	963: "", // o08iwa1 []
//	964: "", // o08iwa1 []
//	965: "", // o08iwa1 []
//	966: "", // cha41a head43e
//	967: "", // cha41a head45d
//	968: "", // takara2 []
//	969: "", // takara3 []
//	970: "", // takara2_02 []
//	971: "", // takara3_02 []
//	973: "", // cha50a head47c
//	974: "", // cha50b head47c
//	975: "", // cha50c head47c
//	976: "", // cha50d head47c
//	977: "", // cha51a head47c
]
