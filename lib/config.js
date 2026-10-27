export const ISSUER_FALLBACK = {
  seller_name:'Tmi Ville Olenius / VIDO Social', business_id:'3581471-7',
  address:'Niittytie 4 D 42, 03100 Nummela', email:'Ville.olenius@gmail.com', phone:'0468802997',
  recipient_name:'Tmi Ville Olenius',bank_iban:'FI98 2077 2000 1432 71',bank_bic:'NDEAFIHH',
  vat_explanation:'Arvonlisäveroton myynti, vähäinen toiminta (AVL 3 §). Myyjä ei ole arvonlisäverovelvollisten rekisterissä.',
  bank_account_confirmed:false,
};
export const PRODUCTS=[
 {sku:'ARV-STD',product:'standard',label:'Google Review Plate, 70 mm',description:'ARVOSTA Google Review Plate 70 mm, NFC + QR, 1 kpl. Toimitus sisältyy hintaan. Valmistetaan tilauksesta maksun vahvistamisen jälkeen.',price_cents:7900},
];
export const QA_STEPS=[
 'Maksun vahvistus ja tilauksen vapautus',
 'Asiakkaan tiedot ja toimitusosoite tarkistettu',
 'Logo ja brändiaineisto hyväksytty',
 'Google-arvostelulinkki varmennettu',
 'QR-koodi generoitu ja skannaus testattu',
 'NFC-tunniste ohjelmoitu ja testattu',
 'Painatus sekä valmis teline tarkastettu',
 'Pakkaus ja lähetysvalmius hyväksytty',
 'Lähetys kirjattu ja seurantatunnus vahvistettu',
];
export const RESULT_LABELS={attempt:'Käyntiyritys',demo:'Esittely',follow_up:'Jatkotoimi',quote_requested:'Tarjouspyyntö',order_requested:'Tilauspyyntö',no_interest:'Ei kiinnostusta'};
export const LEAD_LABELS={review:'Tarkistettava',blocked:'ESTO',previously_contacted:'Aiemmin kontaktoitu',approved:'Hyväksytty',contacted:'Kontaktoitu'};
export const eur=c=>new Intl.NumberFormat('fi-FI',{style:'currency',currency:'EUR'}).format((Number(c)||0)/100);
export const dt=iso=>iso?new Date(iso).toLocaleString('fi-FI',{timeZone:'Europe/Helsinki',day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'}):'—';
export const day=iso=>iso?new Date(iso).toLocaleDateString('fi-FI',{timeZone:'Europe/Helsinki'}):'—';
export const quoteRef=q=>`ARV-${new Date(q.created_at).getFullYear()}-${String(q.quote_no).padStart(5,'0')}`;
export const invoiceRef=i=>`VIDO-${new Date(i.created_at).getFullYear()}-${String(i.invoice_no).padStart(5,'0')}`;
export function validFinnishIban(iban){const s=(iban||'').replace(/\s/g,'').toUpperCase();if(!/^FI\d{16}$/.test(s))return false;const moved=s.slice(4)+'1518'+s.slice(2,4);let n=0;for(const digit of moved)n=(n*10+Number(digit))%97;return n===1;}
