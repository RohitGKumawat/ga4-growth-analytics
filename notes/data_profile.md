 # Self-Report: Cloud vs. My PC

-- 1. Size and shape
This query will process 125.66 MB when run.

-- 2.
This query will process 53.36 MB when run.

-- 3.
This query will process 7.7 MB when run.
1	ga_session_number	26489	0	26489	0
2	page_location	26489	26489	0	0
3	ga_session_id	26489	0	26489	0
4	page_title	26300	26300	0	0
5	engaged_session_event	25404	0	25404	0
6	session_engaged	24183	21601	2582	0
7	debug_mode	21602	0	21602	0
8	page_referrer	20550	6772	0	0
9	engagement_time_msec	15499	0	15499	0
10	source	6436	6436	0	0
11	campaign	6436	6436	0	0
12	medium	6436	6436	0	0
13	all_data	4804	0	0	0
14	clean_event	4804	4804	0	0
15	percent_scrolled	2870	0	2870	0
16	entrances	2624	0	2624	0
17	term	2269	2269	0	0
18	gclid	1535	0	0	0
19	gclsrc	1533	0	0	0
20	search_term	198	198	0	0
21	currency	172	172	0	0
22	unique_search_term	154	0	154	0
23	dclid	124	0	0	0
24	coupon	12	12	0	0
25	promotion_name	5	5	0	0
26	link_domain	3	3	0	0
27	outbound	3	3	0	0
28	link_url	3	3	0	0	

-- 4.
This query will process 811.04 MB when run.
Row	events	events_without_session_id
1	4295584	0

-- 5.
This query will process 61.22 MB when run.
Row	purchase_events	distinct_transaction_ids	missing_transaction_id	missing_revenue	revenue_usd
1	5692	4452	906	0	362165.0

-- 6.
This query will process 169.59 MB when run.
Row	medium	source	users
1	organic	google	103487
2	(none)	(direct)	75951
3	<Other>	<Other>	51037
4	referral	<Other>	32880
5	referral	shop.googlemerchandisestore.com	26065
6	(data deleted)	(data deleted)	17948
7	cpc	google	15527
8	organic	<Other>	10095
9	(data deleted)	<Other>	393
10	referral	(data deleted)	3
11	<Other>	google	1
12	cpc	<Other>	1


-- Sessions in your model, plus a tracking-gap check

Row	sessions	users	engagement_rate	purchasing_sessions	purchases_without_item_view
1	26331	22847	0.9456154342789868	136	3

