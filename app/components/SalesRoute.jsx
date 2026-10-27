'use client';
import {useState} from 'react';
import route from '../../data/ville-route-2026-10-27.json';
const stops=[
['12.00','Nesrin Beauty','Kauppakartanonkatu 26'],
['12.12','Salon Itis','Kauppakartanonkatu 17'],
['12.24','HiuStop','Kauppakartanonkatu 15 C'],
['12.36','Salon Dea','Kauppakartanonkatu 10'],
['12.48','Pizza Service Itäkeskus','Kauppakartanonkatu 5'],
['13.00','World Nails','Easton'],
['13.12','Hiustalo Easton','Easton'],
['13.24','Ella Pizza & Kebab','Easton'],
['13.36','Villa Nepal','Easton'],
['13.48','Salon Looking Good','Easton'],
['14.00','CarStation Easton','Easton']
];
export default function SalesRoute({onOpenCrm}){
const [done,setDone]=useState([]);
return <section className="card sectionGap"><h2>Villen myyntireitti · 27.10.2026</h2><p>{route.startTime} alkaen · {route.area} · Kauppakartanonkatu → Easton</p><p>Suunnitellut käynnit: {stops.length} · Merkitty: {done.length}</p><p><strong>CRM-tarkistus vaaditaan ennen kontaktointia.</strong> Yritysten aiempia kontakteja ja estoja ei ole vahvistettu. Ajat ovat arvioita.</p><ol>{stops.map((s,i)=><li key={i}><label><input type="checkbox" checked={done.includes(i)} onChange={e=>setDone(a=>e.target.checked?[...a,i]:a.filter(x=>x!==i))}/>{s[0]} · {s[1]} — {s[2]}</label></li>)}</ol><p>Merkinnät ovat vain istuntokohtaisia. Kirjaa toteutuneet käynnit CRM:ään.</p><button type="button" onClick={onOpenCrm}>Avaa CRM</button> <a href="https://www.google.com/maps/dir/?api=1&origin=Kauppakartanonkatu%2026%2C%20Helsinki&destination=Easton%20Helsinki%2C%20Kauppakartanonkatu%203%2C%20Helsinki&travelmode=walking" target="_blank" rel="noopener noreferrer">Avaa reitti kartalla</a></section>;
}