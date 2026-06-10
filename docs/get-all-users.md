`GET /api/v1/admin-access/get-all-users`

With header:
Authorization: Bearer <admin_access_token>

```
{
  "success": boolean,
  "code": "SUCCESS",
  "message": "Users retrieved successfully",
  "data": {
    "code": "SUCCESS",
    "status": 200,
    "message": "Request successful",
    "data": {
      "total": number,
      "users": [
        {
          "id": "uuid",
          "name": "string",
          "email": "string",
          "phoneNumber": "+91XXXXXXXXXX",
          "role": "SUPERADMIN" | "ADMIN" | "USER",
          "city": "string",
          "area": "string",
          "companyName": "string" | null,
          "accountStatus": "APPROVED" | "PENDING",
          "userActivationStatus": "ACTIVE",
          "enableAccessTill": "ISO date" | null,
          "createdAt": "ISO date",
          "accessRequests": [
            {
              "id": "uuid",
              "status": "APPROVED",
              "requestedAt": "ISO date",
              "approvedTill": "ISO date",
              "createdAt": "ISO date"
            }
          ]
        }
      ]
    }
  }
}
```


Searching users:
GET /api/v1/admin-access/get-all-users?name=
GET /api/v1/admin-access/get-all-users?email=
GET /api/v1/admin-access/get-all-users?phoneNumber=


and pagination also pass like: {{url}}/api/v1/admin-access/get-all-users?page=1&limit=2