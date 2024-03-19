use immobilier;

## 	Il faut extraire les données suivantes via des requêtes SQL sur les données :

## 		1. Nombre total d’appartements vendus au 1er semestre 2020.
##		2. Le nombre de ventes d’appartement par région pour le 1er semestre 2020.
##		3. Proportion des ventes d’appartements par le nombre de pièces.
##		4. Liste des 10 départements où le prix du mètre carré est le plus élevé.
##		5. Prix moyen du mètre carré d’une maison en Île-de-France.
##		6. Liste des 10 appartements les plus chers avec la région et le nombre
##			de mètres carrés.
##		7. Taux d’évolution du nombre de ventes entre le premier et le second
##			trimestre de 2020.
##		8. Le classement des régions par rapport au prix au mètre carré des
##			appartement de plus de 4 pièces.
##		9. Liste des communes ayant eu au moins 50 ventes au 1er trimestre
##		10. Différence en pourcentage du prix au mètre carré entre un
##			appartement de 2 pièces et un appartement de 3 pièces.
##		11. Les moyennes de valeurs foncières pour le top 3 des communes des
##			départements 6, 13, 33, 59 et 69.



## Requête 1 : 

select count(distinct bien.id_bien) as 'Nombre d appartements vendus au 1er semestre 2020'
from bien
left join vente
on vente.id_bien = bien.id_bien 
where bien.type_local = 'Appartement' 
and vente.date_vente between '2020-01-01' and '2020-06-30';


## Requête 2 :

select nom_region,
count(distinct bien.id_bien) as 'Nombre d appartements vendus'
from bien
inner join vente
on vente.id_bien = bien.id_bien
inner join commune
on bien.id_commune = commune.id_commune
inner join region
on commune.id_region = region.id_region
where bien.type_local = 'Appartement' 
and vente.date_vente between '2020-01-01' and '2020-06-30'
group by nom_region
order by count(distinct bien.id_bien) desc;


## Requête 3 :

select nb_pieces,
count(distinct bien.id_bien) as 'Nombre de bien vendus',
round(count(distinct bien.id_bien)/(select count(distinct id_bien) from bien)*100,2) as 'Proportion d appartements vendus au 1er semestre 2020'
from bien
inner join vente
on vente.id_bien = bien.id_bien 
where bien.type_local = 'Appartement' 
and vente.date_vente between '2020-01-01' and '2020-06-30'
group by bien.nb_pieces
order by bien.nb_pieces asc;


## Requête 4 :

select code_departement,
count(distinct vente.id_bien) as 'Nombre de ventes par département',
round((sum(valeur_fonciere)/sum(surf_carrez)),2) as 'Prix du mètre carré'
from bien
inner join vente
on vente.id_bien = bien.id_bien
inner join commune
on bien.id_commune = commune.id_commune
where vente.date_vente between '2020-01-01' and '2020-06-30'
and valeur_fonciere != 0
group by commune.code_departement
order by round((sum(valeur_fonciere)/sum(surf_carrez)),2) desc
limit 10;


## Requête 5 :

select round(avg(valeur_fonciere/surf_carrez),2) as 'Prix moyen du mètre carré des maisons en Ile-de-France'
from vente
inner join bien
on vente.id_bien = bien.id_bien
inner join commune
on bien.id_commune = commune.id_commune
inner join region
on region.id_region = commune.id_region
where region.nom_region = 'Ile-de-France'
and bien.type_local = 'Maison'
and valeur_fonciere != 0
and vente.date_vente between '2020-01-01' and '2020-06-30';


## Requête 6 :

select distinct vente.id_bien,
code_departement,
nom_region,
surf_carrez
from bien
inner join vente
on vente.id_bien = bien.id_bien
inner join commune
on bien.id_commune = commune.id_commune
inner join region
on region.id_region = commune.id_region
where bien.type_local = 'Appartement'
and vente.date_vente between '2020-01-01' and '2020-06-30'
order by vente.valeur_fonciere desc
limit 10;


## Requête 7 :

with 
ventes1 as (
	select count(distinct id_bien) as trimestre1
    from vente
    where date_vente between '2020-01-01' and '2020-03-31'),
ventes2 as (
	select count(distinct id_bien) as trimestre2
    from vente
    where date_vente between '2020-04-01' and '2020-06-30')
select round((((trimestre2 - trimestre1) / trimestre1) * 100),2) as 'Taux d evolution des ventes entre le 1er et le 2eme trimestre 2020'
from ventes1,ventes2;


## Requête 8 :

select nom_region,
count(distinct vente.id_bien) as 'Nombre d appartements de plus de 4 pièces vendus',
round((sum(valeur_fonciere)/sum(surf_carrez)),2) as 'Prix du mètre carré',
rank() over (order by round((sum(valeur_fonciere)/sum(surf_carrez)),2) desc) as 'Classement'
from bien
inner join vente
on vente.id_bien = bien.id_bien
inner join commune
on bien.id_commune = commune.id_commune
inner join region 
on commune.id_region = region.id_region
where vente.date_vente between '2020-01-01' and '2020-06-30'
and bien.type_local = 'Appartement'
and nb_pieces > 4
and valeur_fonciere != 0
and surf_carrez != 0
and code_departement is not null
group by nom_region
order by round((sum(valeur_fonciere)/sum(surf_carrez)),2) desc;


## Requête 9 :

select nom_commune,
count(distinct vente.id_bien) as 'Nombre de ventes dans la commune'
from commune
inner join bien
on bien.id_commune = commune.id_commune
inner join vente
on vente.id_bien = bien.id_bien
where vente.date_vente between '2020-01-01' and '2020-03-31'
group by commune.nom_commune
having count(distinct vente.id_bien) >= 50
order by count(distinct vente.id_bien) desc;


## Requête 10 :

with
appart2 as (
	select round((sum(valeur_fonciere)/sum(surf_carrez)),2) as prix2p
    from bien
    inner join vente
    on bien.id_bien = vente.id_bien
    where bien.type_local = 'Appartement'
    and valeur_fonciere != 0
    and bien.nb_pieces = 2
    and vente.date_vente between '2020-01-01' and '2020-06-30'),
appart3 as (
	select round((sum(valeur_fonciere)/sum(surf_carrez)),2) as prix3p
    from bien
    inner join vente
    on bien.id_bien = vente.id_bien
    where bien.type_local = 'Appartement'
    and valeur_fonciere != 0
    and bien.nb_pieces = 3
    and vente.date_vente between '2020-01-01' and '2020-06-30')
select round((((prix3p - prix2p)/prix2p)*100),2) as 'Difference de prix d un mètre carré en pourcentage entre les appartements de 2 pièces et les appartements de 3 pièces'
from appart2, appart3;


## Requête 11 :

select *
from
	(select round(avg(valeur_fonciere),2) as 'Moyenne des valeurs foncières',
			nom_commune,
			code_departement,
	rank() over (partition by code_departement order by avg(valeur_fonciere) desc) as Top_3_departement
	from bien
	inner join vente
	on vente.id_bien = bien.id_bien
	inner join commune
	on bien.id_commune = commune.id_commune
	where vente.date_vente between '2020-01-01' and '2020-06-30'
    and valeur_fonciere != 0
	group by nom_commune,
			 code_departement
	order by code_departement,
			 avg(valeur_fonciere) desc) as Classement
where Classement.Top_3_departement <= 3
and code_departement in (6,13,33,59,69);


