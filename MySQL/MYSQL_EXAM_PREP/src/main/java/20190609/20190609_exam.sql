create schema 20190609_db;
use 20190609_db;

# 1. tables design

create table branches
(
    id   int primary key auto_increment,
    name varchar(30) not null unique
);

create table employees
(
    id         int primary key auto_increment,
    first_name varchar(20)    not null,
    last_name  varchar(20)    not null,
    salary     decimal(10, 2) not null,
    started_on date           not null,
    branch_id  int            not null,
    constraint fk_employees_branches
        foreign key (branch_id)
            references branches (id)
);

create table clients
(
    id        int primary key auto_increment,
    full_name varchar(50) not null,
    age       int         not null
);

create table bank_accounts
(
    id             int primary key auto_increment,
    account_number varchar(10)    not null,
    balance        decimal(10, 2) not null,
    client_id      int            not null unique,
    constraint fk_bank_account_client
        foreign key (client_id)
            references clients (id)
);

create table cards
(
    id              int primary key auto_increment,
    card_number     varchar(19) not null,
    card_status     varchar(7)  not null,
    bank_account_id int         not null,
    constraint fk_cards_bank_accounts
        foreign key (bank_account_id)
            references bank_accounts (id)
);

create table employees_clients
(
    employee_id int not null,
    client_id   int not null,
    constraint fk_ec_employees
        foreign key (employee_id)
            references employees (id),
    constraint fk_ec_clients
        foreign key (client_id)
            references clients (id)
);

# 2. insert
insert into cards (card_number, card_status, bank_account_id)
select reverse(c.full_name), 'Active', c.id
from clients c
where c.id between 191 and 200;

# 3. update
update employees_clients
set employee_id = (
    select ec.employee_id
    from (select * from employees_clients) ec
    group by ec.employee_id
    order by count(ec.client_id), employee_id
    limit 1
)
where employee_id = client_id;

# 4. delete
delete
from employees
where id not in (select employee_id from employees_clients);

# 5. clients
select id, full_name
from clients
order by id;

# 6. newbies
select id,
       concat_ws(' ', first_name, last_name) full_name,
       concat('$', salary)                   salary,
       started_on
from employees
where salary >= 100000
  and started_on >= '2018-01-01'
order by salary desc, id;

# 7. cards against humanity
select c.id, concat(c.card_number, ' : ', c2.full_name)
from cards c
         join bank_accounts ba on c.bank_account_id = ba.id
         join clients c2 on ba.client_id = c2.id
order by c.id desc;

# 8. top 5 employees
select concat_ws(' ', e.first_name, e.last_name),
       e.started_on,
       count(ec.client_id) count_of_clints
from employees e
         join employees_clients ec on e.id = ec.employee_id
group by ec.employee_id
order by count_of_clints desc, ec.employee_id
limit 5;

# 9. branch cards
select b.name, count(c.id) count_of_cards
from branches b
         left join employees e on b.id = e.branch_id
         left join employees_clients ec on e.id = ec.employee_id
         left join bank_accounts ba on ec.client_id = ba.client_id
         left join cards c on ba.id = c.bank_account_id
group by b.name
order by count_of_cards desc, b.name;

# 10.	Extract client cards count
create function udf_client_cards_count(name VARCHAR(30))
    returns int
    deterministic
begin
    return (select count(c2.id)
            from clients c
                     join bank_accounts ba on c.id = ba.client_id
                     join cards c2 on ba.id = c2.bank_account_id
            where c.full_name = name
    );
end;

SELECT c.full_name, udf_client_cards_count('Baxy David') as `cards`
FROM clients c
WHERE c.full_name = 'Baxy David';
# Baxy David	6

# 11. client info
create procedure udp_clientinfo(client_full_name varchar(50))
    deterministic
begin
    (select c.full_name, c.age, ba.account_number, concat('$', ba.balance)
     from clients c
              join bank_accounts ba on c.id = ba.client_id
     where c.full_name = client_full_name
    );
end;

call udp_clientinfo('Hunter Wesgate');