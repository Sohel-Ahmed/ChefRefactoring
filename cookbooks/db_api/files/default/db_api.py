from flask import Flask, jsonify

app = Flask(__name__)

DATABASES = {
    'metrics': [{
        'name': 'metrics',
        'tables': [
            """
            create table clicks (
              id serial primary key,
              page text not null,
              created_at timestamp default now()
            );
            """,
            """
            create table page_views (
              id serial primary key,
              url text not null,
              created_at timestamp default now()
            );
            """
        ]
    }],
    'application': [{
        'name': 'app',
        'tables': [
            """
            create table users (
                id serial primary key,
                username text not null check (char_length(first_name) < 80),
                created_at timestamp default now()
            );
            """
        ]
    }]
}

def trim_sql(sql):
    return " ".join([line.strip() for line in sql.splitlines() if line.strip()])

@app.route("/databases/<role>")
def databases(role):
    data = DATABASES.get(role)
    if data:
        # Clean up strings
        for db in data:
            db['tables'] = [trim_sql(table) for table in db['tables']]
        return jsonify(data)
    else:
        abort(404)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
