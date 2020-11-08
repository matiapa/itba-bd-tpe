CREATE TABLE pais(
  	id_pais serial not null primary key,
  	pais text not null
);
CREATE TABLE provincia(
  	provincia int not null primary key,
  	id_pais int not null,
  	foreign key (id_pais) references pais on delete restrict
);
CREATE TABLE departamento(
  	id_departamento serial not null primary key,
  	departamento text not null,
  	provincia int not null,
  	foreign key (provincia) references provincia on delete restrict
);
CREATE TABLE localidad (
  	id_localidad SERIAL NOT NULL PRIMARY KEY,
  	nombre text not null,
  	canthab INT,
  	id_departamento int NOT null,
  	foreign key (id_departamento) references departamento on delete restrict
 );

/* CREATE VIEW view_estructura
 AS 
 	SELECT
    pais.pais,
    provincia.provincia,
    departamento.departamento,
    localidad.nombre,
    localidad.canthab
    FROM pais NATURAL JOIN provincia NATURAL JOIN departamento NATURAL JOIN localidad;
*/
CREATE table aux(
  localidad_nombre text not null,
  pais text not null,
  provincia int not null ,
  departamento text not null,
  localidad_cantHab int 
);




CREATE OR REPLACE FUNCTION insert_tupla() RETURNS trigger AS $$
DECLARE
	pais_id int;
  departamento_id int;
BEGIN
	IF NOT EXISTS(SELECT * FROM pais WHERE pais.pais=NEW.pais) THEN
		INSERT into pais (pais) VALUES(New.pais);
    END IF;
    
    IF NOT EXISTS(SELECT * FROM provincia WHERE provincia.provincia=NEW.provincia) THEN
        SELECT id_pais FROM pais WHERE pais.pais=New.pais INTO pais_id;
        INSERT into provincia(provincia,id_pais) VALUES(NEW.provincia,pais_id);
    END IF;
   	
    IF NOT EXISTS(SELECT * FROM departamento WHERE departamento.departamento=NEW.departamento and departamento.provincia=New.provincia) THEN
        INSERT into departamento(departamento,provincia) VALUES(New.departamento,NEW.provincia);
    End IF;
    
    SELECT id_departamento FROM departamento WHERE (departamento.departamento=New.departamento AND departamento.provincia=New.provincia)INTO departamento_id;
    IF NOT EXISTS(SELECT * FROM localidad WHERE localidad.nombre=NEW.localidad_nombre and localidad.id_departamento=departamento_id) THEN
    	 INSERT INTO localidad (nombre,canthab,id_departamento) VALUES(New.localidad_nombre,new.localidad_cantHab,departamento_id);
    ELSE
    	RAISE 'localidad with that name already exists';
    End IF;
    
   
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_tupla before INSERT ON aux
FOR EACH ROW 
EXECUTE PROCEDURE insert_tupla();

