-- ARVOSTA Sales v3, additive only. No writes to old public VIDO tables.
begin;

create table arvosta.product_catalog (
 sku text primary key,
 title text not null,
 description text not null,
 price_cents integer not null check(price_cents > 0),
 vat_percent numeric(4,1) not null default 0 check(vat_percent=0),
 active boolean not null default true
);
insert into arvosta.product_catalog(sku,title,description,price_cents) values
 ('ARV-STD','ARVOSTA Standard','A6-akryyliteline, brändätty painatus, QR-koodi ja NTAG213 NFC',7900),
 ('ARV-PRM','ARVOSTA Premium','Premium-versio — lisäsisältö vahvistetaan ennen tilausta',9900),
 ('ARV-ADD','Lisäteline','Lisäteline saman tilauksen yhteydessä',4900);

-- FI IBAN: move first four characters to end and check mod 97.
create function arvosta.valid_fi_iban(p_iban text) returns boolean
language plpgsql immutable strict set search_path = pg_catalog as $$
declare s text; rearranged text; i integer; r integer := 0; c text; digits text;
begin
 s := upper(regexp_replace(p_iban,'[[:space:]]','','g'));
 if s !~ '^FI[0-9]{16}$' then return false; end if;
 rearranged := substring(s from 5) || '1518' || substring(s from 3 for 2);
 for i in 1..length(rearranged) loop
   c := substring(rearranged from i for 1);
   r := (r*10 + c::integer) % 97;
 end loop;
 return r = 1;
end $$;
revoke all on function arvosta.valid_fi_iban(text) from public, anon;
grant execute on function arvosta.valid_fi_iban(text) to authenticated;

create table arvosta.billing_settings (
 id integer primary key default 1 check(id=1),
 seller_name text not null,
 business_id text not null,
 address text not null,
 email text not null,
 phone text not null,
 recipient_name text not null,
 bank_iban text not null,
 bank_bic text not null,
 vat_explanation text not null,
 bank_account_confirmed boolean not null default false,
 updated_at timestamptz not null default now(),
 constraint bank_must_be_valid_when_confirmed check(not bank_account_confirmed or arvosta.valid_fi_iban(bank_iban))
);


-- Laskuttajan vahvistetut tekstikentät. Pankkitilin omistajuutta ei ole todennettu.
insert into arvosta.billing_settings
 (id,seller_name,business_id,address,email,phone,recipient_name,bank_iban,bank_bic,vat_explanation,bank_account_confirmed)
values
 (1,'Tmi Ville Olenius / VIDO Social','3581471-7','Niittytie 4 D 42, 03100 Nummela',
  'Ville.olenius@gmail.com','0468802997','Tmi Ville Olenius',
  'FI98 2077 2000 1432 71','NDEAFIHH',
  'Arvonlisäveroa ei veloiteta (myyjä ei ole arvonlisäverovelvollinen).',false);

create table arvosta.pilot_goals (
 id uuid primary key default gen_random_uuid(),
 owner_user_id uuid not null references arvosta.staff(user_id) on delete restrict,
 start_at timestamptz not null,
 area text not null,
 target_visits integer not null default 15 check(target_visits between 0 and 1000),
 target_demos integer not null default 8 check(target_demos between 0 and 1000),
 target_quotes integer not null default 5 check(target_quotes between 0 and 1000),
 target_orders integer not null default 2 check(target_orders between 0 and 1000),
 notes text not null default '',
 created_at timestamptz not null default now(),
 unique(owner_user_id,start_at)
);

create table arvosta.visits (
 id uuid primary key default gen_random_uuid(),
 owner_user_id uuid not null,
 prospect_id uuid not null,
 happened_at timestamptz not null default now(),
 visit_area text not null default '',
 result text not null check(result in ('attempt','demo','follow_up','quote_requested','order_requested','no_interest')),
 notes text not null default '' check(length(notes)<=2000),
 next_action_at timestamptz,
 created_at timestamptz not null default now(),
 foreign key(prospect_id,owner_user_id) references arvosta.prospects(id,owner_user_id) on delete restrict
);
create index arvosta_visits_owner_at on arvosta.visits(owner_user_id,happened_at desc);

create table arvosta.orders (
 id uuid primary key default gen_random_uuid(),
 owner_user_id uuid not null,
 quote_id uuid not null unique,
 acceptance_note text not null check(length(btrim(acceptance_note))>=3),
 customer_accepted_at timestamptz not null,
 status text not null default 'awaiting_payment' check(status in ('awaiting_payment','cancelled')),
 delivery_address text,
 created_at timestamptz not null default now(),
 unique(id,owner_user_id),
 foreign key (quote_id,owner_user_id) references arvosta.quotes(id,owner_user_id) on delete restrict
);
create index arvosta_orders_owner_created on arvosta.orders(owner_user_id,created_at desc);

create table arvosta.payments (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null unique references arvosta.orders(id) on delete restrict,
 amount_cents integer not null check(amount_cents>0),
 method text not null default 'bank_transfer' check(method in ('bank_transfer','provider_confirmation')),
 external_reference text not null check(length(btrim(external_reference))>=5),
 verified_by uuid not null references arvosta.staff(user_id),
 verified_at timestamptz not null default now(),
 note text not null default ''
);

create table arvosta.order_qa (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references arvosta.orders(id) on delete restrict,
 step_no smallint not null check(step_no between 1 and 9),
 evidence_note text not null check(length(btrim(evidence_note))>=4),
 checked_by uuid not null references arvosta.staff(user_id),
 checked_at timestamptz not null default now(),
 unique(order_id,step_no)
);

create table arvosta.shipments (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null unique references arvosta.orders(id) on delete restrict,
 carrier text not null check(length(btrim(carrier))>=2),
 tracking_code text not null check(length(btrim(tracking_code))>=4),
 delivered_to_carrier_at timestamptz not null default now(),
 registered_by uuid not null references arvosta.staff(user_id),
 created_at timestamptz not null default now()
);

create table arvosta.invoices (
 id uuid primary key default gen_random_uuid(),
 invoice_no bigint generated always as identity unique,
 order_id uuid not null unique,
 owner_user_id uuid not null,
 status text not null default 'draft' check(status in ('draft','issued','void')),
 issued_at timestamptz,
 due_date date not null default (current_date + 14),
 iban_snapshot text,
 bic_snapshot text,
 admin_note text not null default '',
 created_at timestamptz not null default now(),
 foreign key(order_id,owner_user_id) references arvosta.orders(id,owner_user_id) on delete restrict,
 constraint invoice_issued_has_bank check(status<>'issued' or (issued_at is not null and iban_snapshot is not null and bic_snapshot is not null))
);

create function arvosta.require_order_payment() returns trigger language plpgsql security invoker
set search_path = pg_catalog, arvosta as $$
declare expected integer;
begin
 select q.amount_cents into expected from arvosta.orders o join arvosta.quotes q on q.id=o.quote_id
 where o.id=new.order_id and o.status='awaiting_payment';
 if expected is null or expected<>new.amount_cents then raise exception 'Paid amount must equal confirmed quote amount'; end if;
 if new.verified_by is distinct from auth.uid() then raise exception 'Payment verifier must be the logged-in admin'; end if;
 return new;
end $$;
create trigger trg_arvosta_payment_guard before insert on arvosta.payments
 for each row execute function arvosta.require_order_payment();

create function arvosta.enforce_qa_sequence() returns trigger language plpgsql security invoker
set search_path = pg_catalog, arvosta as $$
declare count_done integer; ispaid boolean; hasship boolean;
begin
 if new.checked_by is distinct from auth.uid() then raise exception 'QA checker must be logged-in admin'; end if;
 select exists(select 1 from arvosta.payments p where p.order_id=new.order_id) into ispaid;
 if not ispaid then raise exception 'QA is locked until payment is verified'; end if;
 select coalesce(max(step_no),0) into count_done from arvosta.order_qa where order_id=new.order_id;
 if new.step_no<>count_done+1 then raise exception 'QA must follow steps in sequence'; end if;
 if new.step_no=9 then
  select exists(select 1 from arvosta.shipments s where s.order_id=new.order_id) into hasship;
  if not hasship then raise exception 'Shipment tracking required for final QA'; end if;
 end if;
 return new;
end $$;
create trigger trg_arvosta_qa_guard before insert on arvosta.order_qa
 for each row execute function arvosta.enforce_qa_sequence();

create function arvosta.require_shipment_ready() returns trigger language plpgsql security invoker
set search_path = pg_catalog, arvosta as $$
declare complete_count integer;
begin
 if new.registered_by is distinct from auth.uid() then raise exception 'Shipment register must be logged-in admin'; end if;
 select count(*) into complete_count from arvosta.order_qa where order_id=new.order_id;
 if complete_count < 8 then raise exception 'First 8 QA steps required before shipping'; end if;
 return new;
end $$;
create trigger trg_arvosta_shipment_guard before insert on arvosta.shipments
 for each row execute function arvosta.require_shipment_ready();

create function arvosta.invoice_issuing_gate() returns trigger language plpgsql security invoker
set search_path = pg_catalog, arvosta as $$
declare s arvosta.billing_settings%rowtype;
begin
 if tg_op='INSERT' and new.status<>'draft' then raise exception 'Invoice must start as draft'; end if;
 if tg_op='UPDATE' and old.status='void' then raise exception 'Voided invoice is immutable'; end if;
 if tg_op='UPDATE' and old.status='issued' and new.status not in ('issued','void') then raise exception 'Issued invoice cannot revert to draft'; end if;
 if tg_op='UPDATE' and old.status='issued' then
  new.iban_snapshot:=old.iban_snapshot; new.bic_snapshot:=old.bic_snapshot; new.issued_at:=old.issued_at;
  return new;
 end if;
 if new.status='issued' then
  select * into s from arvosta.billing_settings where id=1;
  if not found or not s.bank_account_confirmed or not arvosta.valid_fi_iban(s.bank_iban) then
    raise exception 'Verified valid bank account required before issuing invoice';
  end if;
  new.iban_snapshot:=s.bank_iban; new.bic_snapshot:=s.bank_bic;
  if new.issued_at is null then new.issued_at:=now(); end if;
 end if;
 return new;
end $$;
create trigger trg_arvosta_invoice_guard before insert or update on arvosta.invoices
 for each row execute function arvosta.invoice_issuing_gate();

-- Guard seller-created order from blocked prospect and mismatched quote.
create function arvosta.order_insert_guard() returns trigger language plpgsql security invoker
set search_path = pg_catalog, arvosta as $$
declare s text;
begin
 select p.contact_status into s from arvosta.quotes q join arvosta.prospects p on p.id=q.prospect_id
 where q.id=new.quote_id and q.owner_user_id=new.owner_user_id;
 if s is null or s='blocked' then raise exception 'Blocked or missing prospect'; end if;
 return new;
end $$;
create trigger trg_arvosta_order_guard before insert on arvosta.orders
 for each row execute function arvosta.order_insert_guard();

-- Every table private at PostgREST schema level and protected by RLS.
alter table arvosta.product_catalog enable row level security;
alter table arvosta.billing_settings enable row level security;
alter table arvosta.pilot_goals enable row level security;
alter table arvosta.visits enable row level security;
alter table arvosta.orders enable row level security;
alter table arvosta.payments enable row level security;
alter table arvosta.order_qa enable row level security;
alter table arvosta.shipments enable row level security;
alter table arvosta.invoices enable row level security;
revoke all on all tables in schema arvosta from anon,authenticated,public;
revoke all on all sequences in schema arvosta from anon,authenticated,public;
-- Preserve phase02 intended column restrictions, after blanket revocation.
grant select on arvosta.staff to authenticated;
grant select,insert on arvosta.prospects to authenticated;
grant update(company_name,business_id,contact_name,contact_email,contact_phone,contact_status,notes) on arvosta.prospects to authenticated;
grant select,insert on arvosta.quotes to authenticated;
grant usage,select on sequence arvosta.quotes_quote_no_seq to authenticated;

-- Shared staff existence predicate within policies (non-recursive: own staff select policy).
create policy arvosta_catalog_read on arvosta.product_catalog for select to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_billing_read on arvosta.billing_settings for select to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_billing_admin_update on arvosta.billing_settings for update to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 with check(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));
create policy arvosta_goals_read on arvosta.pilot_goals for select to authenticated
 using((owner_user_id=(select auth.uid()) or exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_goals_edit on arvosta.pilot_goals for update to authenticated
 using(owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active))
 with check(owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_visits_read on arvosta.visits for select to authenticated
 using((owner_user_id=(select auth.uid()) or exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_visits_insert on arvosta.visits for insert to authenticated
 with check(owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_visits_update on arvosta.visits for update to authenticated
 using(owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active))
 with check(owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_orders_read on arvosta.orders for select to authenticated
 using((owner_user_id=(select auth.uid()) or exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_orders_insert on arvosta.orders for insert to authenticated
 with check(owner_user_id=(select auth.uid()) and status='awaiting_payment' and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_payments_admin_read on arvosta.payments for select to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin')
 or exists(select 1 from arvosta.orders o where o.id=order_id and o.owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active)));
create policy arvosta_payments_admin_insert on arvosta.payments for insert to authenticated
 with check(verified_by=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));
create policy arvosta_qa_read on arvosta.order_qa for select to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin')
 or exists(select 1 from arvosta.orders o where o.id=order_id and o.owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active)));
create policy arvosta_qa_admin_insert on arvosta.order_qa for insert to authenticated
 with check(checked_by=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));
create policy arvosta_shipments_read on arvosta.shipments for select to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin')
 or exists(select 1 from arvosta.orders o where o.id=order_id and o.owner_user_id=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active)));
create policy arvosta_shipments_admin_insert on arvosta.shipments for insert to authenticated
 with check(registered_by=(select auth.uid()) and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));
create policy arvosta_invoices_read on arvosta.invoices for select to authenticated
 using((owner_user_id=(select auth.uid()) or exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active));
create policy arvosta_invoices_admin_insert on arvosta.invoices for insert to authenticated
 with check(status='draft' and exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));
create policy arvosta_invoices_admin_update on arvosta.invoices for update to authenticated
 using(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'))
 with check(exists(select 1 from arvosta.staff s where s.user_id=(select auth.uid()) and s.active and s.role='admin'));

-- Only needed operations, never expose anonymous access.
grant select on arvosta.product_catalog, arvosta.billing_settings, arvosta.pilot_goals, arvosta.visits, arvosta.orders,
 arvosta.payments, arvosta.order_qa, arvosta.shipments, arvosta.invoices to authenticated;
grant insert,update(target_visits,target_demos,target_quotes,target_orders,notes) on arvosta.pilot_goals to authenticated;
grant insert,update(happened_at,visit_area,result,notes,next_action_at) on arvosta.visits to authenticated;
grant insert on arvosta.orders to authenticated;
grant insert on arvosta.payments,arvosta.order_qa,arvosta.shipments,arvosta.invoices to authenticated;
grant update(bank_iban,bank_bic,bank_account_confirmed,updated_at) on arvosta.billing_settings to authenticated;
grant update(status,due_date,admin_note) on arvosta.invoices to authenticated;
grant usage,select on sequence arvosta.invoices_invoice_no_seq to authenticated;

-- Only invoker views are exposed through public Data API; public role grants revoked.
create view public.arvosta_catalog_api with (security_invoker=true) as select sku,title,description,price_cents,vat_percent,active from arvosta.product_catalog;
create view public.arvosta_billing_api with (security_invoker=true) as select id,seller_name,business_id,address,email,phone,recipient_name,bank_iban,bank_bic,vat_explanation,bank_account_confirmed,updated_at from arvosta.billing_settings;
create view public.arvosta_goals_api with (security_invoker=true) as select id,owner_user_id,start_at,area,target_visits,target_demos,target_quotes,target_orders,notes,created_at from arvosta.pilot_goals;
create view public.arvosta_visits_api with (security_invoker=true) as select id,owner_user_id,prospect_id,happened_at,visit_area,result,notes,next_action_at,created_at from arvosta.visits;
create view public.arvosta_orders_api with (security_invoker=true) as select id,owner_user_id,quote_id,acceptance_note,customer_accepted_at,status,delivery_address,created_at from arvosta.orders;
create view public.arvosta_payments_api with (security_invoker=true) as select id,order_id,amount_cents,method,external_reference,verified_by,verified_at,note from arvosta.payments;
create view public.arvosta_qa_api with (security_invoker=true) as select id,order_id,step_no,evidence_note,checked_by,checked_at from arvosta.order_qa;
create view public.arvosta_shipments_api with (security_invoker=true) as select id,order_id,carrier,tracking_code,delivered_to_carrier_at,registered_by,created_at from arvosta.shipments;
create view public.arvosta_invoices_api with (security_invoker=true) as select id,invoice_no,order_id,owner_user_id,status,issued_at,due_date,iban_snapshot,bic_snapshot,admin_note,created_at from arvosta.invoices;

revoke all on public.arvosta_catalog_api, public.arvosta_billing_api, public.arvosta_goals_api,public.arvosta_visits_api,public.arvosta_orders_api,
 public.arvosta_payments_api,public.arvosta_qa_api,public.arvosta_shipments_api,public.arvosta_invoices_api from public,anon,authenticated;
grant select on public.arvosta_catalog_api,public.arvosta_billing_api,public.arvosta_goals_api,public.arvosta_visits_api,public.arvosta_orders_api,
 public.arvosta_payments_api,public.arvosta_qa_api,public.arvosta_shipments_api,public.arvosta_invoices_api to authenticated;
grant update(bank_iban,bank_bic,bank_account_confirmed,updated_at) on public.arvosta_billing_api to authenticated;
grant update(target_visits,target_demos,target_quotes,target_orders,notes) on public.arvosta_goals_api to authenticated;
grant insert,update(happened_at,visit_area,result,notes,next_action_at) on public.arvosta_visits_api to authenticated;
grant insert on public.arvosta_orders_api,public.arvosta_payments_api,public.arvosta_qa_api,public.arvosta_shipments_api,public.arvosta_invoices_api to authenticated;
grant update(status,due_date,admin_note) on public.arvosta_invoices_api to authenticated;
commit;
