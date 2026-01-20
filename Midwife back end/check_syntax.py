try:
    from sql_app import crud
    print("Syntax OK")
except Exception as e:
    print(f"Error: {e}")
except SyntaxError as e:
    print(f"SyntaxError: {e}")
